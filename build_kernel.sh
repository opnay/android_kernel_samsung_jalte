#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.6/bin/arm-eabi-

MODEL=$1
VER=$2

if	[ "" = "$1" ]
then
	echo --------------------------------------------------------------------------------
	echo - Useage
	echo -   : ./build_kernel.sh [model] [ver]
	echo -   : ./build_kernel.sh jalteskt 00
	echo --------------------------------------------------------------------------------
	exit
fi
make ${MODEL}_${VER}_defconfig
make