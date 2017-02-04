#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.8/bin/arm-eabi-

make -j8 ARCH=arm ja3g_00_defconfig
make -j8 ARCH=arm
