IMMORTAL_VERSION=v0.23T

JN=16 #`grep process /proc/cpuinfo | wc -l`

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_OUT=$KERNEL_DIR/out
KERNEL_OUT_BOOTIMG=$KERNEL_DIR/bootimg
KERNEL_BIN=$KERNEL_DIR/bin

RAMDISK_DIR=$KERNEL_OUT/ramdisk
RAMDISK_DIR_ORIG=$KERNEL_DIR/ramdisk

## Binary
TOOLCHAIN_PREFIX=/workspace/bin/toolchain/arm-unknown-linux-gnueabihf/bin/arm-unknown-linux-gnueabihf-
strip="$TOOLCHAIN_PREFIX"strip
mkbootfs="$KERNEL_BIN/mkbootfs"
mkbootimg="$KERNEL_BIN/mkbootimg"
mkbootimg_args="--base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048"
