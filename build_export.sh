IMMORTAL_VERSION=v0.1T

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_OUT_DIR=$KERNEL_DIR/out
KERNEL_BOOTIMG_DIR=$KERNEL_DIR/bootimg
KERNEL_BIN_DIR=$KERNEL_DIR/bin
RAMDISK_ORIG=$KERNEL_DIR/ramdisk
RAMDISK_OUT_DIR=$KERNEL_OUT_DIR/ramdisk

## Binary
TOOLCHAIN=/project/toolchain/gcc-linaro-arm-linux-gnueabihf-4.9-2014.06_linux/bin/arm-linux-gnueabihf-
MINIGZIP=$KERNEL_BIN_DIR/minigzip
MKBOOTFS=$KERNEL_BIN_DIR/mkbootfs
MKBOOTIMG=$KERNEL_BIN_DIR/mkbootimg
STRIP="$TOOLCHAIN"strip

NB_CPU=16 #`grep process /proc/cpuinfo | wc -l`
COMPRESS=lz4 # gz / lz4
