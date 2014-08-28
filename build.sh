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
	BOOTIMG=recovery
else
	RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/$1
	BOOTIMG=boot
fi

# Check Settings.
ShowInfo "Check Script Settings\n"

if [ $BOOTIMG == "recovery" ]; then
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
rm -rf $KERNEL_DIR_OUT
mkdir -p $KERNEL_DIR_OUT

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

## Make boot.img
ShowNoty "Make boot.img"
# build_bootimg.sh <original_directory> <out_file_name>
./build_bootimg.sh $RAMDISK_DIR_ORIG $BOOTIMG

if [ -e $KERNEL_DIR_BOOTIMG/$BOOTIMG.img ]; then
ShowNoty "Build Complete!!"
ShowInfo "boot.img: " "$KERNEL_DIR_BOOTIMG/$BOOTIMG.img"
else
Error "Couldn't make boot.img"
fi
