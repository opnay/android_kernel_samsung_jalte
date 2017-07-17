#!/bin/bash
export CROSS_COMPILE=../PLATFORM/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
#rm log.txt
#export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.9/bin/aarch64-linux-android-
export ARCH=arm

make make ja3g_00_defconfig
make -j64