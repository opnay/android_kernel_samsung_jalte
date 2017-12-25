source build/export.sh

# Export
DEFCONFIG=lineageos_immortal_skt_defconfig
BOOTIMG=boot

function help() {
	echo -e "Usage : build.sh [-c|--clean] [-h|--help] <ramdisk>"
	echo -e "  <ramdisk> :"
	echo -e "\tCheck build/ramdisk/<ramdisk> directory"
	exit
}

function echo_work() {
echo "//////"
echo " $@"
echo "//////"
echo ""
}

for tmp in $@; do
	case $tmp in
		-c | --clean) MODE=clean;;
		-h | --help) help; exit;;
		*) RAMDISK=$tmp;;
	esac
done

# Check Settings.
echo_work "Check Settings"

check_files $DEFCONFIG $RAMDISK

echo -e "\nPress [Enter] key to start build"
read

## Clean output Directory
if [ "$MODE" == "clean" ]; then
	echo_work "Clean Directory"
	rm -rf $KERNEL_OUT
fi
mkdir -p $KERNEL_OUT

## Config
echo_work "Make Config"
k_make $DEFCONFIG
sed -i 's/^CONFIG_LOCALVERSION=\"\"/CONFIG_LOCALVERSION=\"-'$IMMORTAL_VERSION'\"/g' $KERNEL_OUT/.config

echo_work "Run Menu Config"
k_make menuconfig

## Make Config
echo_work "Make zImage"
k_make

if [ ! -e $KERNEL_OUT/arch/arm/boot/zImage ]; then
	echo " ***** Error occured *****"
	exit
fi

## Make boot.img
echo_work "Make boot.img"
./build/build_bootimg.sh -o $BOOTIMG $RAMDISK

if [ -e $KERNEL_BUILD_OUT/$BOOTIMG.img ]; then
	echo "Build Complete!!"
	echo "boot.img : $KERNEL_BUILD_OUT/$BOOTIMG.img"
else
	echo "Couldn't make boot.img"
fi

#### End
