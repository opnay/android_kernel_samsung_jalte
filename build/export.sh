IMMORTAL_VERSION=immortal-lineage-v1

JN=16 #`grep process /proc/cpuinfo | wc -l`

## Kernel Directory
KERNEL_DIR=`pwd`
KERNEL_OUT=$KERNEL_DIR/out
KERNEL_BUILD=$KERNEL_DIR/build
KERNEL_BUILD_OUT=$KERNEL_DIR/build/out
KERNEL_BIN=$KERNEL_BUILD/bin

RAMDISK_OUT=$KERNEL_BUILD_OUT/ramdisk
RAMDISK_ORIG=$KERNEL_BUILD/ramdisk

## Binary
TOOLCHAIN_PREFIX=/workspace/bin/gcc-linaro-4.9.4-2017.01-x86_64_arm-eabi/bin/arm-eabi-
strip="${TOOLCHAIN_PREFIX}strip --strip-unneeded"
mkbootimg="${KERNEL_BIN}/mkbootimg \
    --base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048"

function k_make() {
    fakeroot make -j$JN O=$KERNEL_OUT ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX $@
}

function check_files() {
    echo " Kernel : $KERNEL_DIR"
    echo " Output : $KERNEL_OUT"
    echo " Build out : $KERNEL_BUILD_OUT"
    echo " Ramdisk : $RAMDISK_ORIG/$2"
    if [ ! -e $RAMDISK_ORIG/$2 ]; then
        echo -e "\n ***** Ramdisk directory was not found *****"
        exit
    fi
    echo " Toolchain : $TOOLCHAIN_PREFIX"
    if [ ! -e "$TOOLCHAIN_PREFIX"ld ]; then
        echo -e "\n ***** Toolchain was not found *****"
        exit
    fi
    echo " Make job number : $JN"
    echo " Defconfig : $1"
    if [ ! -e $KERNEL_DIR/arch/arm/configs/$1 ]; then
        echo -e "\n ***** Defconfig was not found *****"
        exit
    fi
}