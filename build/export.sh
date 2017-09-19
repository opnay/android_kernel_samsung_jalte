IMMORTAL_VERSION=v1.14

JN=16 #`grep process /proc/cpuinfo | wc -l`

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_OUT=$KERNEL_DIR/out
KERNEL_BUILD=$KERNEL_DIR/build
KERNEL_BUILD_OUT=$KERNEL_BUILD/out
KERNEL_BIN=$KERNEL_BUILD/bin

RAMDISK_OUT=$KERNEL_BUILD_OUT/ramdisk
RAMDISK_ORIG=$KERNEL_BUILD/ramdisk

## Binary
TOOLCHAIN_PREFIX=/workspace/bin/gcc-linaro-5.4.1-2017.05-x86_64_arm-eabi/bin/arm-eabi-
strip="$TOOLCHAIN_PREFIX"strip
mkbootfs="$KERNEL_BIN/mkbootfs"
mkbootimg="$KERNEL_DIR/scripts/mkbootimg"
mkbootimg_args="--base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048"
