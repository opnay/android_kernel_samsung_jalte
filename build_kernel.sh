#!/bin/bash

BUILD_TOP_DIR=$(pwd)

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.6/bin/arm-eabi-

make jalteskt_00_defconfig
make