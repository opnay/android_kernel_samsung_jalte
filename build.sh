export ARCH=arm
export CROSS_COMPILE=/home/op_nay/toolchain/android-toolchain-eabi-4.8-13.12/bin/arm-eabi-
#get kernel directory(current directory) from terminal
KERNDIR=`pwd`
KERNDIR_OUT=$KERNDIR/out
INITRAM_ORIG=/home/op_nay/android/initram
INITRAM_DIR=$KERNDIR_OUT/initramfs
jobn=16

#Set Color
function echo_error() {
	echo -e "\e[01m\e[31m$* \e[00m"
}

function echo_info() {
	echo -e "\e[36m$1 \e[00m"
	if [ "$2" != "" ]
	then
		echo -e "\t\e[32m$2 \e[00m"
	fi
}

function echo_notify() {
	echo -e "\e[33m$*\e[00m"
}

if [ "$1" == "" ]
then
	echo_error "build.sh [ skt / kt / lg ]"
	echo_error "Initramfs directory will be set \"$INITRAM_ORIG/<skt / kt / lg>\""
	exit
else
	INITRAM_ORIG="$INITRAM_ORIG/$1"
fi
DEFCONFIG=immortal_"$1"_defconfig

echo_notify "Check Settings"
echo_info "ARCH : " $ARCH
echo_info "Kernel Directory : " $KERNDIR
echo_info "Tool Chain : " $CROSS_COMPILE
echo_info "Initramfs Source : " $INITRAM_ORIG
echo_info "Defconfig : " $DEFCONFIG


if [ -e $INITRAM_ORIG ]
then
        echo_info "Ramdisk is exist"
else
        echo_error "No such directory"
        exit 1
fi

if [ ! -e "$KERNDIR/arch/arm/configs/$DEFCONFIG" ]
then
        echo_error "Configuration file $DEFCONFIG don't exists"
        exit 1
fi


echo_notify "----------------------------------------------------------------------------------------------------------CLEAN"
rm -rf $KERNDIR/out_bootimg $KERNDIR_OUT
mkdir $KERNDIR/out_bootimg $KERNDIR_OUT $INITRAM_DIR
echo_notify "----------------------------------------------------------------------------------------------------------CONFIG"
make $DEFCONFIG menuconfig O=$KERNDIR_OUT
echo_notify "----------------------------------------------------------------------------------------------------------BUILD"
make -j$jobn O=$KERNDIR_OUT
if [ ! -e $KERNDIR_OUT/arch/arm/boot/zImage ]
then
	echo_error "Error occured"
	exit
fi
echo_notify "----------------------------------------------------------------------------------------------------------INITRAMFS"
# copy original initramfs directory to kernel directory
cp -r $INITRAM_ORIG/* $INITRAM_DIR/
# remove backup files
find $INITRAM_DIR -name "*~" -exec rm -rf {} \;

# find and copy modulized files
for module_file in `find $KERNDIR_OUT -name "*.ko"`
do
	echo $module_file
	"$CROSS_COMPILE"strip --strip-unneeded $module_file
	cp $module_file $INITRAM_DIR/lib/modules/
done
# make initramfs file
cd $INITRAM_DIR
find . | cpio -o -H newc | gzip > $KERNDIR/out_bootimg/ramdisk.cpio.gz

echo_notify "----------------------------------------------------------------------------------------------------------BOOTIMG"
cd $KERNDIR/out_bootimg

$KERNDIR/mkbootimg --base 0x10000000 --pagesize 2048 --ramdisk_offset 0x01000000 --kernel $KERNDIR_OUT/arch/arm/boot/zImage --ramdisk ramdisk.cpio.gz -o boot.img

if [ -e $KERNDIR/out_bootimg/boot.img ]
then
	echo_info "Build Complete"
else
	echo_error "Couldn't make boot.img"
	exit
fi

$KERNDIR/build_md5.sh ImmortalKernel_"$1" boot.img
