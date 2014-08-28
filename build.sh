source build_function.sh
source build_export.sh

# Check Usage
if [ "$1" == "" ]; then
	Error "Usage :\nbuild.sh <skt/kt/lg> [recovery]"
	exit
fi

# Export
export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN

DEVICE_CA=$1
DEFCONFIG=jalte"$1"_immortal_defconfig
if [ "$2" == "recovery" ]; then
	RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/recovery
	IS_RECOVERY=true
else
	RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/$1
	IS_RECOVERY=false
fi

# Check Settings.
ShowInfo "Check Script Settings\n"

if [ $IS_RECOVERY ]; then
	ShowInfo "Recovery Build :" "true"
fi
ShowInfo "Kernel Directory :" $KERNEL_DIR
ShowInfo "Kernel Output Directory :" $KERNEL_DIR_OUT
ShowInfo "Kernel Output boot.img Directory :" $KERNEL_DIR_BOOTIMG
ShowInfo "Ramdisk Directory :" $RAMDISK_DIR_ORIG
if [ ! -e $RAMDISK_DIR_ORIG ]; then
	Error "Ramdisk Directory Not Found!"
	exit
fi
ShowInfo "Compress :" $COMPRESS
ShowInfo "Toolchain : " $CROSS_COMPILE
if [ ! -e "$CROSS_COMPILE"ld ]; then
	Error "Toolchain Not found!"
	exit
fi
ShowInfo "Allow jobs at once : " $JN
ShowInfo "Defconfig : " $DEFCONFIG
if [ ! -e $KERNEL_DIR/arch/arm/configs/$DEFCONFIG ]; then
	Error "Defconfig Not Found!"
	exit
fi


## Clean output Directory
ShowNoty "Clean Directory"
rm -rf $KERNEL_DIR_BOOTIMG $KERNEL_DIR_OUT
mkdir -p $KERNEL_DIR_BOOTIMG $KERNEL_DIR_OUT $RAMDISK_DIR

## Make
ShowNoty "Make Config"
make $DEFCONFIG -j$JN O=$KERNEL_DIR_OUT
make menuconfig -j$JN O=$KERNEL_DIR_OUT

ShowNoty "Start Make"
make -j$JN O=$KERNEL_DIR_OUT

if [ ! -e $KERNEL_DIR_OUT/arch/arm/boot/zImage ]; then
	Error "Error occured!"
	exit
fi

cp $KERNEL_DIR_OUT/arch/arm/boot/zImage $KERNEL_DIR_BOOTIMG/zImage

## Copy Ramdisk
ShowNoty "Make Ramdisk"
# build_ramdisk.sh <original_directory> <compress_type>
./build_ramdisk.sh $RAMDISK_DIR_ORIG $COMPRESS

## Make boot.img
ShowNoty "Make Boot.img"

if [ $IS_RECOVERY ]; then
$MKBOOTIMG --base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048 \
    --kernel $KERNEL_DIR_BOOTIMG/zImage \
    --ramdisk $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.$COMPRESS \
    -o $KERNEL_DIR_BOOTIMG/recovery.img
else
$MKBOOTIMG --base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048 \
    --kernel $KERNEL_DIR_BOOTIMG/zImage \
    --ramdisk $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.$COMPRESS \
    -o $KERNEL_DIR_BOOTIMG/boot.img
fi

# ShowNoty "==Install boot.img"
# ./build_install.sh $KERNEL_DIR_BOOTIMG/boot.img /dev/block/platform/dw_mmc.0/by-name/BOOT

if [ -e $KERNEL_DIR_BOOTIMG/boot.img -o -e $KERNEL_DIR_BOOTIMG/recovery.img ]; then
ShowNoty "Build Complete!!"
ShowInfo "boot.img: " "$KERNEL_DIR_BOOTIMG/boot.img"
else
Error "Couldn't make boot.img"
fi
