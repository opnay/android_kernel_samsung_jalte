IMMORTAL_VERSION=v1.14

JN=16 #`grep process /proc/cpuinfo | wc -l`

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_OUT=$KERNEL_DIR/out
KERNEL_BUILD=$KERNEL_DIR/build
KERNEL_OUT_BOOTIMG=$KERNEL_BUILD/bootimg
KERNEL_OUT_FLASHZIP=$KERNEL_OUT/flashzip
KERNEL_BIN=$KERNEL_DIR/bin

RAMDISK_DIR=$KERNEL_OUT/ramdisk
RAMDISK_DIR_ORIG=$KERNEL_DIR/ramdisk

## Binary
TOOLCHAIN_PREFIX=/workspace/bin/gcc-linaro-5.4.1-2017.05-x86_64_arm-eabi/bin/arm-eabi-
strip="$TOOLCHAIN_PREFIX"strip
mkbootfs="$KERNEL_BIN/mkbootfs"
mkbootimg="$KERNEL_DIR/scripts/mkbootimg"
mkbootimg_args="--base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048"
