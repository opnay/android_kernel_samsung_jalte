
obj-y += mutex.o rwsem.o

ifdef CONFIG_FUNCTION_TRACER
CFLAGS_REMOVE_mutex-debug.o = -pg
CFLAGS_REMOVE_rtmutex-debug.o = -pg
endif

obj-$(CONFIG_DEBUG_MUTEXES) += mutex-debug.o
obj-$(CONFIG_SMP) += spinlock.o
obj-$(CONFIG_PROVE_LOCKING) += spinlock.o
obj-$(CONFIG_DEBUG_SPINLOCK) += spinlock.o
obj-$(CONFIG_DEBUG_SPINLOCK) += spinlock_debug.o
obj-$(CONFIG_RWSEM_GENERIC_SPINLOCK) += rwsem-spinlock.o
obj-$(CONFIG_RWSEM_XCHGADD_ALGORITHM) += rwsem-xadd.o