/*
 * arch/arm/common/bL_switcher.c -- big.LITTLE cluster switcher core driver
 *
 * Created by:	Nicolas Pitre, March 2012
 * Copyright:	(C) 2012  Linaro Limited
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * TODO:
 *
 * - Allow the outbound CPU to remain online for the inbound CPU to snoop its
 *   cache for a while.
 * - Perform a switch during initialization to probe what the counterpart
 *   CPU's GIC interface ID is and stop hardcoding them in the code.
 * - Local timers migration (they are not supported at the moment).
 */

#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/interrupt.h>
#include <linux/cpu_pm.h>
#include <linux/cpu.h>
#include <linux/cpumask.h>
#include <linux/kthread.h>
#include <linux/wait.h>
#include <linux/clockchips.h>
#include <linux/hrtimer.h>
#include <linux/tick.h>
#include <linux/mm.h>
#include <linux/string.h>
#include <linux/spinlock.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>

#include <asm/smp_plat.h>
#include <asm/cputype.h>
#include <asm/suspend.h>
#include <asm/hardware/gic.h>
#include <asm/bL_switcher.h>
#include <asm/bL_entry.h>
#include <asm/uaccess.h>
#include <mach/sec_debug.h>

/*
 * Notifier list for kernel code which want to called at switch.
 * This is used to stop a switch. If some driver want to keep doing
 * some work without switch, the driver registers the notifier and
 * the notifier callback deal with refusing a switch and some work.
 */
ATOMIC_NOTIFIER_HEAD(bL_switcher_notifier_list);

int register_bL_swicher_notifier(struct notifier_block *nb)
{
	return atomic_notifier_chain_register(&bL_switcher_notifier_list, nb);
}

int unregister_bL_swicher_notifier(struct notifier_block *nb)
{
	return atomic_notifier_chain_unregister(&bL_switcher_notifier_list, nb);
}

/*
 * Before migrating cpu, swicher core driver ask to some dirver
 * whether carries out a switch or not.
 *
 * Switcher core driver decides to do a switch through return value
 * (-) minus value : refuse a switch
 * (+) plus value : go on a switch
 */
static int bL_enter_migration(void)
{
	return atomic_notifier_call_chain(&bL_switcher_notifier_list, SWITCH_ENTER, NULL);
}

static int bL_exit_migration(void)
{
       return atomic_notifier_call_chain(&bL_switcher_notifier_list, SWITCH_EXIT, NULL);
}

/*
 * Use our own MPIDR accessors as the generic ones in asm/cputype.h have
 * __attribute_const__ and we don't want the compiler to assume any
 * constness here.
 */

static int read_mpidr(void)
{
	unsigned int id;
	asm volatile ("mrc\tp15, 0, %0, c0, c0, 5" : "=r" (id));
	return id & MPIDR_HWID_BITMASK;
}

/*
 * bL switcher core code.
 */

const struct bL_power_ops *bL_platform_ops;

extern void setup_mm_for_reboot(void);

typedef void (*phys_reset_t)(unsigned long);

static void bL_do_switch(void *_unused)
{
	unsigned mpidr, cpuid, clusterid, ob_cluster, ib_cluster;
	phys_reset_t phys_reset;

	pr_debug("%s\n", __func__);

	mpidr = read_mpidr();
	cpuid = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	clusterid = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	ob_cluster = clusterid;
	ib_cluster = clusterid ^ 1;

	/*
	 * Our state has been saved at this point.  Let's release our
	 * inbound CPU.
	 */
	bL_set_entry_vector(cpuid, ib_cluster, cpu_resume);
	sev();

	/*
	 * From this point, we must assume that our counterpart CPU might
	 * have taken over in its parallel world already, as if execution
	 * just returned from cpu_suspend().  It is therefore important to
	 * be very careful not to make any change the other guy is not
	 * expecting.  This is why we need stack isolation.
	 *
	 * Also, because of this special stack, we cannot rely on anything
	 * that expects a valid 'current' pointer.  For example, printk()
	 * may give bogus "BUG: recent printk recursion!\n" messages
	 * because of that.
	 */
	bL_platform_ops->power_down(cpuid, ob_cluster);

	/*
	 * Hey, we're not dead!  This means a request to switch back
	 * has come from our counterpart and reset was deasserted before
	 * we had the chance to enter WFI.  Let's turn off the MMU and
	 * branch back directly through our kernel entry point.
	 */
	setup_mm_for_reboot();
	phys_reset = (phys_reset_t)(unsigned long)virt_to_phys(cpu_reset);
	phys_reset(virt_to_phys(bl_entry_point));

	/* should never get here */
	BUG();
}

/*
 * Stack isolation.  To ensure 'current' remains valid, we just use another
 * piece of our thread's stack space which should be fairly lightly used.
 * The selected area starts just above the thread_info structure located
 * at the very bottom of the stack, aligned to a cache line, and indexed
 * with the cluster number.
 */
#define STACK_SIZE 512
extern void call_with_stack(void (*fn)(void *), void *arg, void *sp);
static int bL_switchpoint(unsigned long _arg)
{
	unsigned int mpidr = read_mpidr();
	unsigned int clusterid = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	void *stack = current_thread_info() + 1;
	stack = PTR_ALIGN(stack, L1_CACHE_BYTES);
	stack += clusterid * STACK_SIZE + STACK_SIZE;
	call_with_stack(bL_do_switch, (void *)_arg, stack);
	BUG();

	/*
	 * For removing warning message of compiler, the statement of return
	 * is added, but this return is nothing to this function.
	 */
	return 0;
}

/*
 * Generic switcher interface
 */
static DEFINE_SPINLOCK(switch_gic_lock);

static unsigned int bL_gic_id[BL_CPUS_PER_CLUSTER][BL_NR_CLUSTERS];

/*
 * bL_switch_to - Switch to a specific cluster for the current CPU
 * @new_cluster_id: the ID of the cluster to switch to.
 *
 * This function must be called on the CPU to be switched.
 * Returns 0 on success, else a negative status code.
 */
static int bL_switch_to(unsigned int new_cluster_id)
{
	unsigned int mpidr, cpuid, clusterid, ob_cluster, ib_cluster, this_cpu;
	struct tick_device *tdev;
	enum clock_event_mode tdev_mode;
	int ret = 0;

	mpidr = read_mpidr();
	cpuid = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	clusterid = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	ob_cluster = clusterid;
	ib_cluster = clusterid ^ 1;

	if (new_cluster_id == clusterid)
		return 0;

	if (!bL_platform_ops)
		return -ENOSYS;

	pr_debug("before switch: CPU %d in cluster %d\n", cpuid, clusterid);
	sec_debug_task_log_msg(cpuid, "switch+");

	/* Close the gate for our entry vectors */
	bL_set_entry_vector(cpuid, ob_cluster, NULL);
	bL_set_entry_vector(cpuid, ib_cluster, NULL);

	/*
	 * From this point we are entering the switch critical zone
	 * and can't sleep/schedule anymore.
	 */
	local_irq_disable();

	this_cpu = smp_processor_id();
	
	/*
	 * Get spin_lock to protect concurrent accesses of GIC registers
	 * from both NWd(gic_migrate_target) and SWd(SMC of bL_power_up).
	 */
	spin_lock(&switch_gic_lock);

	/*
	 * Let's wake up the inbound CPU now in case it requires some delay
	 * to come online, but leave it gated in our entry vector code.
	 */
	bL_platform_ops->power_up(cpuid, ib_cluster);

	/* redirect GIC's SGIs to our counterpart */
	gic_migrate_target(bL_gic_id[cpuid][ib_cluster]);

	/*
	 * Raise a SGI on the inbound CPU to make sure it doesn't stall
	 * in a possible WFI, such as the one in bL_do_switch().
	 */
	arm_send_ping_ipi(this_cpu);

	spin_unlock(&switch_gic_lock);

	tdev = tick_get_device(this_cpu);
	if (tdev && !cpumask_equal(tdev->evtdev->cpumask, cpumask_of(this_cpu)))
		tdev = NULL;
	if (tdev) {
		tdev_mode = tdev->evtdev->mode;
		clockevents_set_mode(tdev->evtdev, CLOCK_EVT_MODE_SHUTDOWN);
	}

	ret = cpu_pm_enter();
	if (ret)
		goto out;

	/* Let's do the actual CPU switch. */
	ret = cpu_suspend((unsigned long)NULL, bL_switchpoint);
	if (ret > 0)
		ret = -EINVAL;

	/* We are executing on the inbound CPU at this point */
	mpidr = read_mpidr();
	cpuid = MPIDR_AFFINITY_LEVEL(mpidr, 0);
	clusterid = MPIDR_AFFINITY_LEVEL(mpidr, 1);
	pr_debug("after switch: CPU %d in cluster %d\n", cpuid, clusterid);
	sec_debug_task_log_msg(cpuid, "switch-");
	BUG_ON(clusterid != ib_cluster);

	bL_platform_ops->inbound_setup(cpuid, !clusterid);
	ret = cpu_pm_exit();

out:
	if (tdev) {
		clockevents_set_mode(tdev->evtdev, tdev_mode);
		clockevents_program_event(tdev->evtdev,
					  tdev->evtdev->next_event, 1);
	}

	local_irq_enable();

	if (ret)
		pr_err("%s exiting with error %d\n", __func__, ret);
	return ret;
}

struct bL_thread {
	struct task_struct *task;
	wait_queue_head_t wq;
	int wanted_cluster;
};

static struct bL_thread bL_threads[NR_CPUS];

#ifdef CONFIG_ARM_EXYNOS_IKS_CPUFREQ
static int switch_ready = -1;
static DEFINE_SPINLOCK(switch_ready_lock);
#define BL_TIMEOUT_NS 50000000
#endif

static int bL_switcher_thread(void *arg)
{
	struct bL_thread *t = arg;
	struct sched_param param = { .sched_priority = 1 };
	int ret;

	sched_setscheduler_nocheck(current, SCHED_FIFO, &param);

#ifdef CONFIG_ARM_EXYNOS_IKS_CPUFREQ
	do {
		ret = wait_event_interruptible(t->wq, t->wanted_cluster != -1);
		if (!ret) {
			int cluster = t->wanted_cluster;
#ifdef CONFIG_EXYNOS5_CCI
			t->wanted_cluster = -1;
			bL_switch_to(cluster);
#else
			static atomic_t switch_ready_cnt = ATOMIC_INIT(0);
			unsigned long long start = sched_clock();
			unsigned int cpuid = get_cpu();
			signed long long wait_time = 0;

			atomic_inc(&switch_ready_cnt);
			dmb();

			spin_lock(&switch_ready_lock);
			if (switch_ready < 0) {
				while (atomic_read(&switch_ready_cnt) <
						num_online_cpus()) {
					wait_time = sched_clock() - start;
					if ((wait_time > BL_TIMEOUT_NS) ||
							(wait_time < 0))
						break;
				}

				if (wait_time > BL_TIMEOUT_NS) {
					switch_ready = 0;
					pr_info("%s: aborted on CPU %d by timeout (%ld msecs)\n",
							__func__, cpuid,
							(int) wait_time / NSEC_PER_MSEC);
				} else if (wait_time < 0) {
					switch_ready = 0;
					pr_info("%s: sched_clock is reversed\n",
							__func__);
				} else {
					switch_ready = 1;
				}
			}
			spin_unlock(&switch_ready_lock);

			atomic_dec(&switch_ready_cnt);

			t->wanted_cluster = -1;

			spin_lock(&switch_ready_lock);
			if (switch_ready == 1) {
				spin_unlock(&switch_ready_lock);
				/* condition met before timeout */
				bL_switch_to(cluster);
			} else {
				spin_unlock(&switch_ready_lock);
			}

			put_cpu();
#endif
		}
	} while (!kthread_should_stop());

	return ret;
#else
	do {
		if (signal_pending(current))
			flush_signals(current);
		wait_event_interruptible(t->wq,
				t->wanted_cluster != -1 ||
				kthread_should_stop());
		cluster = xchg(&t->wanted_cluster, -1);
		if (cluster != -1)
			bL_switch_to(cluster);
	} while (!kthread_should_stop());
	
	return 0;
#endif
}

static struct task_struct * __init bL_switcher_thread_create(int cpu, void *arg)
{
	struct task_struct *task;

	task = kthread_create_on_node(bL_switcher_thread, arg,
				      cpu_to_node(cpu), "kswitcher_%d", cpu);
	if (!IS_ERR(task)) {
		kthread_bind(task, cpu);
		wake_up_process(task);
	} else
		pr_err("%s failed for CPU %d\n", __func__, cpu);
	return task;
}

/*
 * bL_switch_request - Switch to a specific cluster for the given CPU
 *
 * @cpu: the CPU to switch
 * @new_cluster_id: the ID of the cluster to switch to.
 *
 * This function causes a cluster switch on the given CPU by waking up
 * the appropriate switcher thread.  This function may or may not return
 * before the switch has occurred.
 */
int bL_switch_request(unsigned int cpu, unsigned int new_cluster_id)
{
	struct bL_thread *t;

	if (cpu >= ARRAY_SIZE(bL_threads)) {
		pr_err("%s: cpu %d out of bounds\n", __func__, cpu);
		return -EINVAL;
	}

	t = &bL_threads[cpu];
	if (IS_ERR(t->task))
		return PTR_ERR(t->task);
	if (!t->task)
		return -ESRCH;

	t->wanted_cluster = new_cluster_id;
	wake_up(&t->wq);
	return 0;
}

EXPORT_SYMBOL_GPL(bL_switch_request);

int bL_cluster_switch_request(unsigned int new_cluster)
{
	struct bL_thread *t;
	int cpu;
	int ret;

	BUG_ON(new_cluster >= 2);

	get_online_cpus();

	spin_lock(&switch_ready_lock);
	switch_ready = -1;
	spin_unlock(&switch_ready_lock);

	local_irq_disable();
	if (bL_enter_migration() < 0) {
		local_irq_enable();
		put_online_cpus();
		return -EPERM;
	}

	for (cpu = BL_CPUS_PER_CLUSTER - 1; cpu >= 0; cpu--) {
		if (unlikely(!cpu_online(cpu)))
			continue;

		t = &bL_threads[cpu];

		if (unlikely(IS_ERR_OR_NULL(t->task))) {
			pr_err("%s: cpu %d out of bounds\n", __func__, cpu);
			ret = PTR_ERR(t->task);
			if (!ret)
				ret = -ENODEV;
			local_irq_enable();
			put_online_cpus();
			return ret;
		}

		t->wanted_cluster = new_cluster;
		wake_up(&t->wq);
		smp_send_reschedule(cpu);
	}
	local_irq_enable();
	schedule();
	put_online_cpus();

	bL_exit_migration();

	ret = MPIDR_AFFINITY_LEVEL(read_mpidr(), 1) == new_cluster ? 0 : -EBUSY;
	return ret;
}

EXPORT_SYMBOL_GPL(bL_cluster_switch_request);

/*
 * Activation and configuration code.
 */

static cpumask_t bL_switcher_removed_logical_cpus;

static void __init bL_switcher_restore_cpus(void)
{
	int i;

	for_each_cpu(i, &bL_switcher_removed_logical_cpus)
		cpu_up(i);
}

static int __init bL_switcher_halve_cpus(void)
{
	int cpu, cluster, i, ret;
	cpumask_t cluster_mask[2], common_mask;

	cpumask_clear(&bL_switcher_removed_logical_cpus);
	cpumask_clear(&cluster_mask[0]);
	cpumask_clear(&cluster_mask[1]);

	for_each_online_cpu(i) {
		cpu = cpu_logical_map(i) & 0xff;
		cluster = (cpu_logical_map(i) >> 8) & 0xff;
		if (cluster >= 2) {
			pr_err("%s: only dual cluster systems are supported\n", __func__);
			return -EINVAL;
		}
		cpumask_set_cpu(cpu, &cluster_mask[cluster]);
	}

	if (!cpumask_and(&common_mask, &cluster_mask[0], &cluster_mask[1])) {
		pr_err("%s: no common set of CPUs\n", __func__);
		return -EINVAL;
	}

	for_each_online_cpu(i) {
		cpu = cpu_logical_map(i) & 0xff;
		cluster = (cpu_logical_map(i) >> 8) & 0xff;

		if (cpumask_test_cpu(cpu, &common_mask)) {
			/* Let's take note of the GIC ID for this CPU */
			int gic_id = gic_get_cpu_id(i);
			if (gic_id < 0) {
				pr_err("%s: bad GIC ID for CPU %d\n", __func__, i);
				return -EINVAL;
			}
			bL_gic_id[cpu][cluster] = gic_id;
			pr_info("GIC ID for CPU %u cluster %u is %u\n",
				cpu, cluster, gic_id);

			/*
			 * We keep only those logical CPUs which number
			 * is equal to their physical CPU number. This is
			 * not perfect but good enough for now.
			 */
			if (cpu == i)
				continue;
		}

		ret = cpu_down(i);
		if (ret) {
			bL_switcher_restore_cpus();
			return ret;
		}
		cpumask_set_cpu(i, &bL_switcher_removed_logical_cpus);
	}

	return 0;
}

int __init bL_switcher_init(const struct bL_power_ops *ops)
{
	int cpu, ret;

	pr_info("big.LITTLE switcher initializing\n");

	if (BL_NR_CLUSTERS != 2) {
		pr_err("%s: only dual cluster systems are supported\n", __func__);
		return -EINVAL;
	}

	cpu_hotplug_driver_lock();
	ret = bL_switcher_halve_cpus();
	if (ret) {
		cpu_hotplug_driver_unlock();
		return ret;
	}

	ret = bL_cluster_sync_init(ops);
	if (ret)
		return ret;

	bL_platform_ops = ops;

	for_each_online_cpu(cpu) {
		struct bL_thread *t = &bL_threads[cpu];
		init_waitqueue_head(&t->wq);
		t->wanted_cluster = -1;
		t->task = bL_switcher_thread_create(cpu, t);
	}
	cpu_hotplug_driver_unlock();

	pr_info("big.LITTLE switcher initialized\n");
	return 0;
}
