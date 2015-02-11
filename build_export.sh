IMMORTAL_VERSION=v0.22T

JN=16 #`grep process /proc/cpuinfo | wc -l`
COMPRESS=lz4 # gz / lz4

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_DIR_OUT=$KERNEL_DIR/out
KERNEL_DIR_BOOTIMG=$KERNEL_DIR/bootimg
KERNEL_DIR_BIN=$KERNEL_DIR/bin

RAMDISK_DIR=$KERNEL_DIR_OUT/ramdisk
RAMDISK_DIR_ORIG=$KERNEL_DIR/ramdisk

## Binary
TOOLCHAIN=/workspace/bin/toolchain/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
MINIGZIP=$KERNEL_DIR_BIN/minigzip
MKBOOTFS=$KERNEL_DIR_BIN/mkbootfs
MKBOOTIMG="$KERNEL_DIR_BIN/mkbootimg --base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048 \
    --kernel $KERNEL_DIR_BOOTIMG/zImage \
    --ramdisk $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.$COMPRESS"
STRIP="$TOOLCHAIN"strip
