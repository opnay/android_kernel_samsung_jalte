#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.8/bin/arm-eabi-

make -j8 ARCH=arm lineageos_ja3gxx_defconfig
make -j8 ARCH=arm
