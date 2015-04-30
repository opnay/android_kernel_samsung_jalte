source build_export.sh

# Check Usage
if [ $# -lt 1 -o "$1" == "" ]; then
	echo -e "Usage : build.sh <skt/kt/lg> [recovery]"
	exit
fi

# Export
export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN_PREFIX

DEVICE_CA=$1
DEFCONFIG=jalte"$1"_immortal_defconfig
if [ "$2" == "recovery" ]; then
	RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/recovery
	BOOTIMG=recovery
else
	RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/immortal
	BOOTIMG=boot
fi

# Check Settings.
echo "Check Script Settings"

if [ $BOOTIMG == "recovery" ]; then
	echo " * Recovery Build : true"
fi
echo " * Kernel Directory : $KERNEL_DIR"
echo " * Output Directory : $KERNEL_OUT"
echo " * boot.img Directory : $KERNEL_OUT_BOOTIMG"
echo " * Ramdisk Directory : $RAMDISK_DIR_ORIG"
if [ ! -e $RAMDISK_DIR_ORIG ]; then
	echo " ***** Ramdisk directory was not found *****"
	exit
fi
echo " * Toolchain : $CROSS_COMPILE"
if [ ! -e "$CROSS_COMPILE"ld ]; then
	echo " ***** Toolchain was not found *****"
	exit
fi
echo " * Make job number : $JN"
echo " * Defconfig : $DEFCONFIG"
if [ ! -e $KERNEL_DIR/arch/arm/configs/$DEFCONFIG ]; then
	echo " ***** Defconfig was not found *****"
	exit
fi

echo -e "\nPress [Enter] key to start build"
read

## Clean output Directory
echo " ** Clean Directory"
rm -rf $KERNEL_OUT
mkdir -p $KERNEL_OUT

## Config
echo " ** Make Config"
make $DEFCONFIG -j$JN O=$KERNEL_OUT
echo " ** Run menuconfig"
make menuconfig -j$JN O=$KERNEL_OUT

## Make Config
echo " ** Make zImage"
make -j$JN O=$KERNEL_OUT

if [ ! -e $KERNEL_OUT/arch/arm/boot/zImage ]; then
	echo " ***** Error occured *****"
	exit
fi

## Make boot.img
echo " ** Make bootimg"
./build_bootimg.sh -o $BOOTIMG $RAMDISK_DIR_ORIG

if [ -e $KERNEL_OUT_BOOTIMG/$BOOTIMG.img ]; then
	echo "Build Complete!!"
	echo "boot.img : $KERNEL_OUT_BOOTIMG/$BOOTIMG.img"
else
	echo "Couldn't make boot.img"
fi

#### End
