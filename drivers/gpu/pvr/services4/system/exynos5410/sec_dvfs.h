/* /drivers/gpu/pvr/services4/system/exynos5410/sec_dvfs.h
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

#ifndef __SEC_DVFS_H__
#define __SEC_DVFS_H__
typedef struct _GPU_DVFS_DATA_TAG_ {
	int clock;
	int voltage;
	int threshold;
} GPU_DVFS_DATA, *pGPU_DVFS_DATA;

#ifdef USING_532MHZ
#define DVFS_LEN	7
#else
#define DVFS_LEN	4
#endif

#define MAX_DVFS_LEVEL			(DVFS_LEN - 1)
#define BASE_START_LEVEL		0
#define DVFS_HIGH_CLOCK_LEVEL	1	// 480Mhz, 350Mhz

static GPU_DVFS_DATA dvfs_data[DVFS_LEN] = {
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

void sec_gpu_dvfs_init(void);
int sec_clock_change(int level);
int sec_gpu_dvfs_level_from_clk_get(int clock);
void sec_gpu_dvfs_down_requirement_reset(void);
int sec_custom_threshold_set(void);
void sec_gpu_dvfs_handler(int utilization_value);
#endif /*__SEC_DVFS_H__*/