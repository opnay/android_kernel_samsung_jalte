#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.8/bin/arm-eabi-

make -j8 ARCH=arm lineageos_i9500_defconfig
make -j8 ARCH=arm
