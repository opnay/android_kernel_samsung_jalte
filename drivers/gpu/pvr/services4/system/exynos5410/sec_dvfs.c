/* /drivers/gpu/pvr/services4/system/exynos5410/sec_dvfs.c
 *
 * Copyright 2011 by S.LSI. Samsung Electronics Inc.
 * San#24, Nongseo-Dong, Giheung-Gu, Yongin, Korea
 *
 * Samsung SoC SGX DVFS driver
 *
 * This software is proprietary of Samsung Electronics. 
 * No part of this software, either material or conceptual may be copied or distributed, transmitted,
 * transcribed, stored in a retrieval system or translated into any human or computer language in any form by any means,
 * electronic, mechanical, manual or otherwise, or disclosed
 * to third parties without the express written permission of Samsung Electronics.
 *
 * Alternatively, this program is free software in case of Linux Kernel; 
 * you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/platform_device.h>
#include <linux/module.h>
#include <linux/io.h>
#include <linux/device.h>
#include <plat/cpu.h>
#include <mach/asv-exynos.h>

#include "services_headers.h"
#include "sysinfo.h"
#include "sec_dvfs.h"
#include "sec_control_pwr_clk.h"
#include "sec_clock.h"

#define MAX_DVFS_LEVEL			ARRAY_SIZE(dvfs_data)
#define BASE_START_LEVEL		0
#define DVFS_UP_THRESHOLD		150
#define DVFS_DOWN_THRESHOLD		20
#define DVFS_HIGH_CLOCK_LEVEL	1	// 480Mhz
#define DVFS_HIGH_THRESHOLD		200
#define DVFS_HIGH_DOWN_THRESHOLD	50
#define TURBO_UTILIZATION_THRESHOLD	50

#define DVFS_STAY_COUNT_DEFAULT		2
#define DVFS_STAY_COUNT_HIGH		1

static GPU_DVFS_DATA dvfs_data[] = {
/* clock, voltage, stay */
#ifdef USING_532MHZ
	{ 532, 1100000, 180 }, // Level 0
	{ 480, 1050000, 100 },
	{ 440,  975000,  60 },
	{ 350,  925000,  40 },
	{ 333,  925000,  20 },
	{ 266,  900000,  10 },
	{ 177,  900000,   0 },
#else
	{ 480, 1100000, 170 }, // Level 0
	{ 350,  925000, 160 },
	{ 266,  900000, 150 },
	{ 177,  900000,   0 },
#endif

};

bool gpu_idle = false;
int sgx_dvfs_level = -1;
int sgx_dvfs_min_lock;
int sgx_dvfs_max_lock;
int sgx_dvfs_down_requirement;
int custom_min_lock_level;
int custom_max_lock_level;
char sgx_dvfs_table_string[256]={0};
char* sgx_dvfs_table;
/* set sys parameters */
module_param(sgx_dvfs_level, int, S_IRUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(sgx_dvfs_level, "SGX DVFS status");
module_param(sgx_dvfs_table, charp , S_IRUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(sgx_dvfs_table, "SGX DVFS frequency array (Mhz)");

#ifdef CONFIG_ASV_MARGIN_TEST
static int set_g3d_freq = 0;
static int __init get_g3d_freq(char *str)
{
	get_option(&str, &set_g3d_freq);
	return 0;
}
early_param("g3dfreq", get_g3d_freq);
#endif
/* end sys parameters */

static int sec_gpu_lock_control_proc(int bmax, long value, size_t count)
{
	int lock_level = sec_gpu_dvfs_level_from_clk_get(value);
	int retval = -EINVAL;

	sgx_dvfs_level = sec_gpu_dvfs_level_from_clk_get(gpu_clock_get());
	if (lock_level < 0) { /* unlock something */
		if (bmax)
			sgx_dvfs_max_lock = custom_max_lock_level = 0;
		else
			sgx_dvfs_min_lock = custom_min_lock_level = 0;

		if (sgx_dvfs_min_lock && (sgx_dvfs_level > custom_min_lock_level)) /* min lock only - likely */
			sec_gpu_vol_clk_change(dvfs_data[custom_min_lock_level].clock, dvfs_data[custom_min_lock_level].voltage);
		else if (sgx_dvfs_max_lock && (sgx_dvfs_level < custom_max_lock_level)) /* max lock only - unlikely */
			sec_gpu_vol_clk_change(dvfs_data[custom_max_lock_level].clock, dvfs_data[custom_max_lock_level].voltage);

		if (value == 0)
			retval = count;
	} else{ /* lock something */
		if (bmax) {
			sgx_dvfs_max_lock = value;
			custom_max_lock_level = lock_level;
		} else {
			sgx_dvfs_min_lock = value;
			custom_min_lock_level = lock_level;
		}

        if ((sgx_dvfs_max_lock) && (sgx_dvfs_min_lock) && (sgx_dvfs_max_lock < sgx_dvfs_min_lock)){ /* abnormal status */
			if (sgx_dvfs_max_lock) /* max lock */
				sec_gpu_vol_clk_change(dvfs_data[custom_max_lock_level].clock, dvfs_data[custom_max_lock_level].voltage);
		} else { /* normal status */
			if ((bmax) && sgx_dvfs_max_lock && (sgx_dvfs_level < custom_max_lock_level)) /* max lock */
				sec_gpu_vol_clk_change(dvfs_data[custom_max_lock_level].clock, dvfs_data[custom_max_lock_level].voltage);
			if ((!bmax) && sgx_dvfs_min_lock && (sgx_dvfs_level > custom_min_lock_level)) /* min lock */
				sec_gpu_vol_clk_change(dvfs_data[custom_min_lock_level].clock, dvfs_data[custom_min_lock_level].voltage);
		}
		retval = count;
	}
	return retval;
}

static ssize_t get_dvfs_table(struct device *d, struct device_attribute *a, char *buf)
{
	return snprintf(buf, sizeof(sgx_dvfs_table_string), "%s\n", sgx_dvfs_table);
}
static DEVICE_ATTR(sgx_dvfs_table, S_IRUGO | S_IRGRP | S_IROTH, get_dvfs_table, 0);

static ssize_t get_min_clock(struct device *d, struct device_attribute *a, char *buf)
{
	PVR_LOG(("get_min_clock: %d MHz", sgx_dvfs_min_lock));
	return snprintf(buf, sizeof(sgx_dvfs_min_lock), "%d\n", sgx_dvfs_min_lock);
}

static ssize_t set_min_clock(struct device *d, struct device_attribute *a, const char *buf, size_t count)
{
	long value;
	if (kstrtol(buf, 10, &value) == -EINVAL)
		return -EINVAL;
	return sec_gpu_lock_control_proc(0, value, count);
}
static DEVICE_ATTR(sgx_dvfs_min_lock, S_IRUGO | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH, get_min_clock, set_min_clock);

static ssize_t get_max_clock(struct device *d, struct device_attribute *a, char *buf)
{
	PVR_LOG(("get_max_clock: %d MHz", sgx_dvfs_max_lock));
	return snprintf(buf, sizeof(sgx_dvfs_max_lock), "%d\n", sgx_dvfs_max_lock);
}

static ssize_t set_max_clock(struct device *d, struct device_attribute *a, const char *buf, size_t count)
{
	long value;
	if (kstrtol(buf, 10, &value) == -EINVAL)
		return -EINVAL;
	return sec_gpu_lock_control_proc(1, value, count);
}
static DEVICE_ATTR(sgx_dvfs_max_lock, S_IRUGO | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH, get_max_clock, set_max_clock);

static ssize_t get_cur_clock(struct device *d, struct device_attribute *a, char *buf)
{
	return sprintf(buf, "%d\n",
		(!!gpu_idle) ? 0 : dvfs_data[sgx_dvfs_level].clock);
}
static DEVICE_ATTR(sgx_dvfs_cur_clk, S_IRUGO | S_IRGRP | S_IROTH, get_cur_clock, NULL);

void sec_gpu_dvfs_init(void)
{
	struct platform_device *pdev;
	int i = 0;
	ssize_t total = 0, offset = 0;

	/* default dvfs level depend on default clock setting */
	sgx_dvfs_level = sec_gpu_dvfs_level_from_clk_get(gpu_clock_get());
	sgx_dvfs_down_requirement = DVFS_STAY_COUNT_DEFAULT;

	pdev = gpsPVRLDMDev;

	/* Required name attribute */
	if (device_create_file(&pdev->dev, &dev_attr_sgx_dvfs_min_lock) < 0)
		PVR_LOG(("device_create_file: dev_attr_sgx_dvfs_min_lock fail"));
	if (device_create_file(&pdev->dev, &dev_attr_sgx_dvfs_max_lock) < 0)
		PVR_LOG(("device_create_file: dev_attr_sgx_dvfs_max_lock fail"));
	if (device_create_file(&pdev->dev, &dev_attr_sgx_dvfs_cur_clk) <0)
		PVR_LOG(("device_create_file: dev_attr_sgx_dvfs_cur_clk fail"));

	 /* Generate DVFS table list*/
	for( i = 0; i < sizeof(dvfs_data) / sizeof(GPU_DVFS_DATA) ; i++) {
	    offset = snprintf(sgx_dvfs_table_string+total, sizeof(sgx_dvfs_table_string), "%d ", dvfs_data[i].clock);
	    total += offset;
	}
	sgx_dvfs_table = sgx_dvfs_table_string;
	if (device_create_file(&pdev->dev, &dev_attr_sgx_dvfs_table) < 0)
		PVR_LOG(("device_create_file: dev_attr_sgx_dvfs_table fail"));
}

int sec_gpu_dvfs_level_from_clk_get(int clock)
{
	int i = 0;

	for (i = 0; i < MAX_DVFS_LEVEL; i++) {
		/* This is necessary because the intent
		 * is the difference of kernel clock value
		 * and sgx clock table value to calibrate it */
		if ((dvfs_data[i].clock / 10) == (clock / 10))
			return i;
	}
	return -1;
}

void sec_gpu_dvfs_down_requirement_reset()
{
	sgx_dvfs_down_requirement =
		(sgx_dvfs_level <= DVFS_HIGH_CLOCK_LEVEL) ? DVFS_STAY_COUNT_HIGH : DVFS_STAY_COUNT_DEFAULT;
}

extern unsigned int *g_debug_CCB_Info_RO;
extern unsigned int *g_debug_CCB_Info_WO;
extern int g_debug_CCB_Info_WCNT;
static int g_debug_CCB_Info_Flag = 0;
static int g_debug_CCB_count = 1;
int sec_clock_change(int level) {
	PVR_LOG(("INFO: %s: Get value: %d", __func__, level));

	if (level >= MAX_DVFS_LEVEL)
		level = MAX_DVFS_LEVEL - 1;
	else if (level < 0)
		level = 0;

	sec_gpu_vol_clk_change(dvfs_data[level].clock, dvfs_data[level].voltage);
	sec_gpu_dvfs_down_requirement_reset();

	if ((g_debug_CCB_Info_Flag % g_debug_CCB_count) == 0)
		PVR_LOG(("SGX CCB RO : %d, WO : %d, Total : %d", *g_debug_CCB_Info_RO, *g_debug_CCB_Info_WO, g_debug_CCB_Info_WCNT));

	g_debug_CCB_Info_WCNT = 0;
	g_debug_CCB_Info_Flag ++;

	return level;
}

int util_value = 0;
void sec_gpu_dvfs_handler(int utilization_value)
{
	int i, level = 0;

	if (utilization_value < 0) { // gpu going to idle
		gpu_idle = true;
		util_value = 0;
		return;
	}

	PVR_LOG(("INFO: %s: Get value: %d", __func__, utilization_value));

	gpu_idle = false;

#ifdef CONFIG_ASV_MARGIN_TEST
	if (!!set_g3d_freq && (gpu_clock_get() != set_g3d_freq)) {
		level = sec_gpu_dvfs_level_from_clk_get(set_g3d_freq);
		/* this check for current clock must be find in dvfs table */
		if (level < 0) {
			PVR_LOG(("WARN: custom clock: %d MHz not found in DVFS table", set_g3d_freq));
			return;
		}

		if (level < MAX_DVFS_LEVEL && level >= 0) {
			PVR_LOG(("INFO: CUSTOM DVFS [%d MHz] (%d), utilization [%d]",
					dvfs_data[level].clock,
					dvfs_data[level].threshold,
					utilization_value
					));
			goto change;
		}
	}
#endif
	level = sec_gpu_dvfs_level_from_clk_get(gpu_clock_get());
	/* this check for current clock must be find in dvfs table */
	if (level < 0) {
		PVR_LOG(("WARN: current clock: %d MHz not found in DVFS table. so set to max clock", gpu_clock_get()));
		sec_gpu_vol_clk_change(dvfs_data[BASE_START_LEVEL].clock, dvfs_data[BASE_START_LEVEL].voltage);
		return;
	}

	PVR_DPF((PVR_DBG_MESSAGE, "INFO: AUTO DVFS [%d MHz] <%d>, utilization [%d]",
			gpu_clock_get(),
			dvfs_data[level].threshold, utilization_value));

	if (level == (MAX_DVFS_LEVEL - 1)) {
		// for lowest clock
		for (i = 0; i < MAX_DVFS_LEVEL; i++) {
			if (dvfs_data[i].threshold <= utilization_value) {
				level = (sgx_dvfs_max_lock && (i < custom_max_lock_level)) ? custom_max_lock_level : i;
				goto change;
			}
		}
	} else if (level <= DVFS_HIGH_CLOCK_LEVEL) {
		// for high clock
		if (utilization_value < DVFS_HIGH_DOWN_THRESHOLD) {
			level += 1;

			if (sgx_dvfs_min_lock && (level > custom_min_lock_level))
				level = custom_min_lock_level;
			
			goto change;
		}
	} else {
		// for the other clocks
		if (utilization_value >= DVFS_UP_THRESHOLD) { // to UP
			level -= ((utilization_value - util_value) >= TURBO_UTILIZATION_THRESHOLD) ? 1 : 2;

			if (sgx_dvfs_max_lock && (level < custom_max_lock_level))
				level = custom_max_lock_level;

			if ((level <= DVFS_HIGH_CLOCK_LEVEL) && (utilization_value < DVFS_HIGH_THRESHOLD))
				level = DVFS_HIGH_CLOCK_LEVEL + 1;

			goto change;
		} else if (utilization_value < DVFS_DOWN_THRESHOLD) { // to DOWN
			if (--sgx_dvfs_down_requirement > 0)
				goto exit;

			level += 1;

			if (sgx_dvfs_min_lock && (level > custom_min_lock_level))
				level = custom_min_lock_level;

			goto change;
		} else {
			// Stay reset count
			sec_gpu_dvfs_down_requirement_reset();
			goto exit;
		}
	}

change:
	sgx_dvfs_level = sec_clock_change(level);
exit:
	util_value = utilization_value;
	return;
}