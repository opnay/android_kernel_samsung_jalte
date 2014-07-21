source build_function.sh
source build_export.sh
if [ "$1" == "" ]
then
	Error "USE : build.sh <skt/kt/lg>"
	exit
fi

export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN

DEVICE_CA=$1
DEFCONFIG=jalte"$DEVICE_CA"_immortal_defconfig
RAMDISK_ORIG=$RAMDISK_ORIG/$1



echo
ShowInfo "Check Script Settings"
echo
ShowInfo "Kernel Directory :" $KERNEL_DIR
ShowInfo "Kernel Output Directory :" $KERNEL_OUT_DIR
ShowInfo "Kernel Output boot.img Directory :" $KERNEL_BOOTIMG_DIR
ShowInfo "Ramdisk Directory :" $RAMDISK_ORIG
if [ ! -e $RAMDISK_ORIG ]
then
	Error "Ramdisk Directory Not Found!"
	exit
fi
ShowInfo "Toolchain : " $CROSS_COMPILE
if [ ! -e "$CROSS_COMPILE"ld ]
then
	Error "Toolchain Not found!"
	exit
fi
ShowInfo "Number of CPU Core : " $NB_CPU
ShowInfo "Defconfig : " $DEFCONFIG
if [ ! -e $KERNEL_DIR/arch/arm/configs/$DEFCONFIG ]
then
	Error "Defconfig Not Found!"
	exit
fi


## Clean output Directory
rm -rf $KERNEL_BOOTIMG_DIR $KERNEL_OUT_DIR
mkdir -p $KERNEL_BOOTIMG_DIR $KERNEL_OUT_DIR $RAMDISK_OUT_DIR

## Make
ShowNoty "==Make Config"
make $DEFCONFIG -j$NB_CPU O=$KERNEL_OUT_DIR
make menuconfig -j$NB_CPU O=$KERNEL_OUT_DIR

ShowNoty "==Start Make"
make -j$NB_CPU O=$KERNEL_OUT_DIR

if [ ! -e $KERNEL_OUT_DIR/arch/arm/boot/zImage ]
then
	Error "Error occured!"
	exit
fi

## Copy Ramdisk
ShowNoty "==Make Ramdisk"
cp -r $RAMDISK_ORIG/* $RAMDISK_OUT_DIR/
find $RAMDISK_OUT_DIR -name EMPTY -exec rm -rf {} \;
find $RAMDISK_OUT_DIR -name "*~" -exec rm -rf {} \;

for module_file in `find $KERNDIR_OUT -name "*.ko"`
do
	echo $module_file
	$STRIP --strip-unneeded $module_file
	cp $module_file $RAMDISK_OUT_DIR/lib/modules/
done

ShowNoty "==Make Boot.img"
$MKBOOTFS $RAMDISK_OUT_DIR > $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio
# GZip
# $MINIGZIP < $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio > $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.gz

# LZ4
lz4c -l -hc stdin $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.lz4 < $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio

$MKBOOTIMG --base 0x10000000 --pagesize 2048 --kernel $KERNEL_OUT_DIR/arch/arm/boot/zImage --ramdisk $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.lz4 -o $KERNEL_BOOTIMG_DIR/boot.img
ShowNoty "==Install boot.img"
$KERNEL_DIR/build_install.sh $KERNEL_BOOTIMG_DIR/boot.img /dev/block/platform/dw_mmc.0/by-name/BOOT
