source build_function.sh
source build_export.sh

# Check Usage
if [ "$1" == "" ]; then
	Error "Usage :\nbuild.sh <skt/kt/lg>"
	exit
fi

# Export
export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN

DEVICE_CA=$1
DEFCONFIG=jalte"$DEVICE_CA"_immortal_defconfig
RAMDISK_ORIG=$RAMDISK_ORIG/$1

# Check Settings.
ShowInfo "Check Script Settings"
echo
ShowInfo "Kernel Directory :" $KERNEL_DIR
ShowInfo "Kernel Output Directory :" $KERNEL_OUT_DIR
ShowInfo "Kernel Output boot.img Directory :" $KERNEL_BOOTIMG_DIR
ShowInfo "Ramdisk Directory :" $RAMDISK_ORIG
ShowInfo "Compress :" $COMPRESS
if [ ! -e $RAMDISK_ORIG ]; then
	Error "Ramdisk Directory Not Found!"
	exit
fi
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
rm -rf $KERNEL_BOOTIMG_DIR $KERNEL_OUT_DIR
mkdir -p $KERNEL_BOOTIMG_DIR $KERNEL_OUT_DIR $RAMDISK_OUT_DIR

## Make
ShowNoty "Make Config"
make $DEFCONFIG -j$JN O=$KERNEL_OUT_DIR
make menuconfig -j$JN O=$KERNEL_OUT_DIR

ShowNoty "Start Make"
make -j$JN O=$KERNEL_OUT_DIR

if [ ! -e $KERNEL_OUT_DIR/arch/arm/boot/zImage ]; then
	Error "Error occured!"
	exit
fi

cp $KERNEL_OUT_DIR/arch/arm/boot/zImage $KERNEL_BOOTIMG_DIR/zImage

## Copy Ramdisk
ShowNoty "Make Ramdisk"
cp -r $RAMDISK_ORIG/* $RAMDISK_OUT_DIR/
find $RAMDISK_OUT_DIR -name EMPTY -exec rm -rf {} \;
find $RAMDISK_OUT_DIR -name "*~" -exec rm -rf {} \;

# Strip modules
for i in `find $KERNDIR_OUT -name "*.ko"`; do
	echo $i
	$STRIP --strip-unneeded $i
	cp $i $RAMDISK_OUT_DIR/lib/modules/
done

## Set Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_OUT_DIR/default.prop

## Make boot.img
ShowNoty "Make Boot.img"
./build_ramdisk.sh $RAMDISK_OUT_DIR $COMPRESS

$MKBOOTIMG \
    --base 0x10000000 \
    --ramdisk_offset 0x01000000 \
    --pagesize 2048 \
    --kernel $KERNEL_BOOTIMG_DIR/zImage \
    --ramdisk $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.$COMPRESS \
    -o $KERNEL_BOOTIMG_DIR/boot.img

# ShowNoty "==Install boot.img"
# ./build_install.sh $KERNEL_BOOTIMG_DIR/boot.img /dev/block/platform/dw_mmc.0/by-name/BOOT

ShowNoty "Build Complete!!"
ShowInfo "boot.img: " "$KERNEL_BOOTIMG_DIR/boot.img\n\n"
