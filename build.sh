source build_export.sh

# Export
export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN_PREFIX

function help() {
	echo -e "Usage : build.sh <skt/kt/lg> <ramdisk>"
	echo -e "  <ramdisk> :"
	echo -e "\ttw-kitkat\tSamsung Touchwiz Kitkat"
	echo -e "\ttw-lollipop\tSamsung Touchwiz Lollipop"
	echo -e "\trecovery\tCWM Recovery"
	echo -e "\trecovery-cm\tCyanogenMod Recovery"
	echo -e "\trecovery-philz\tPhilz Touch Recovery"
	exit
}

# Check Usage
if [ $# != 2 ]; then
	help
fi

case $1 in
	skt) DEFCONFIG=jalteskt_immortal_defconfig;;
	lg) DEFCONFIG=jaltelgt_immortal_defconfig;;
	kt) DEFCONFIG=jaltektt_immortal_defconfig;;
	*) help;;
esac

RAMDISK_DIR_ORIG=$RAMDISK_DIR_ORIG/$2

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
#rm -rf $KERNEL_OUT
mkdir -p $KERNEL_OUT

## Config
echo " ** Make Config"
make $DEFCONFIG -j$JN O=$KERNEL_OUT
sed -i 's/^CONFIG_LOCALVERSION=\"\"/CONFIG_LOCALVERSION=\"-'$IMMORTAL_VERSION'\"/g' $KERNEL_OUT/.config
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
./build_bootimg.sh -o $BOOTIMG $2

if [ -e $KERNEL_OUT_BOOTIMG/$BOOTIMG.img ]; then
	echo "Build Complete!!"
	echo "boot.img : $KERNEL_OUT_BOOTIMG/$BOOTIMG.img"
else
	echo "Couldn't make boot.img"
fi

#### End
