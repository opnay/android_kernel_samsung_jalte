source build/export.sh

# Export
export ARCH=arm
export CROSS_COMPILE=$TOOLCHAIN_PREFIX
DEFCONFIG=none
BOOTIMG=boot

function help() {
	echo -e "Usage : build.sh [-r | --recovery] <skt/kt/lg> <ramdisk>"
	echo -e "  <ramdisk> :"
	echo -e "\ttw-kitkat\tSamsung Touchwiz Kitkat"
	echo -e "\ttw-lollipop\tSamsung Touchwiz Lollipop"
	echo -e "\trecovery\tCWM Recovery"
	echo -e "\trecovery-cm\tCyanogenMod Recovery"
	echo -e "\trecovery-philz\tPhilz Touch Recovery"
	exit
}

for tmp in $@; do
	case $tmp in
		skt) DEFCONFIG=jalteskt_immortal_defconfig;;
		lg) DEFCONFIG=jaltelgt_immortal_defconfig;;
		kt) DEFCONFIG=jaltektt_immortal_defconfig;;
		-r | --recovery) BOOTIMG=recovery;;
		-h | --help) help; exit;;
		*) RAMDISK=$tmp;;
	esac
done

# Check Settings.
echo -e "==== Check Settings\n"

if [ $BOOTIMG == "recovery" ]; then
	echo "== Recovery Build "
fi
echo " Kernel : $KERNEL_DIR"
echo " Output : $KERNEL_OUT"
echo " Build out : $KERNEL_BUILD_OUT"
echo " Ramdisk : $RAMDISK_ORIG/$RAMDISK"
if [ ! -e $RAMDISK_ORIG/$RAMDISK ]; then
	echo -e "\n ***** Ramdisk directory was not found *****"
	exit
fi
echo " Toolchain : $CROSS_COMPILE"
if [ ! -e "$CROSS_COMPILE"ld ]; then
	echo -e "\n ***** Toolchain was not found *****"
	exit
fi
echo " Make job number : $JN"
echo " Defconfig : $DEFCONFIG"
if [ ! -e $KERNEL_DIR/arch/arm/configs/$DEFCONFIG ]; then
	echo -e "\n ***** Defconfig was not found *****"
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
echo -e "\n ** Make bootimg"
./build/build_bootimg.sh -o $BOOTIMG $RAMDISK

if [ -e $KERNEL_BUILD_OUT/$BOOTIMG.img ]; then
	echo "Build Complete!!"
	echo "boot.img : $KERNEL_BUILD_OUT/$BOOTIMG.img"
else
	echo "Couldn't make boot.img"
fi

#### End
