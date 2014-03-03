export ARCH=arm
export CROSS_COMPILE=/home/op_nay/toolchain/android-toolchain-eabi-4.8-14.01/bin/arm-eabi- ##### Set your toolchain directory
KERNDIR=`pwd`
KERNDIR_OUT=$KERNDIR/out
INITRAM_ORIG=/home/op_nay/android/initram ##### original ramdisk directory
INITRAM_DIR=$KERNDIR_OUT/initramfs ##### Tmp directory for 
DEVICE_CARRIER=$1
jobn=16 ##### Your CPU core * 2

##### Set output color function

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

##### Check args...

if [ "$DEVICE_CARRIER" == "" ]
then
	echo_error "build.sh [ skt / kt / lg ]"
	echo_error "Initramfs directory will be set \"$INITRAM_ORIG/<skt / kt / lg>\""
	exit
else
	INITRAM_ORIG="$INITRAM_ORIG/$DEVICE_CARRIER"
fi
DEFCONFIG=immortal_"$DEVICE_CARRIER"_defconfig

##### Showing script config values

echo_notify "Check Settings"
echo_info "Carrier : " $DEVICE_CARRIER
echo_info "ARCH : " $ARCH
echo_info "Kernel Directory : " $KERNDIR
echo_info "Tool Chain : " $CROSS_COMPILE
echo_info "Initramfs Source : " $INITRAM_ORIG
echo_info "Defconfig : " $DEFCONFIG

##### Checking ramdisk and defconfigs

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

##### Remove files which before built

rm -rf $KERNDIR/out_bootimg $KERNDIR_OUT
mkdir $KERNDIR/out_bootimg $KERNDIR_OUT $INITRAM_DIR
make $DEFCONFIG menuconfig O=$KERNDIR_OUT
make -j$jobn O=$KERNDIR_OUT
if [ ! -e $KERNDIR_OUT/arch/arm/boot/zImage ]
then
	echo_error "Error occured"
	exit
fi

##### Copy ramdisk to tmp folder on kernel directory

cp -r $INITRAM_ORIG/* $INITRAM_DIR/
find $INITRAM_DIR -name EMPTY -exec rm -rf {} \;
find $INITRAM_DIR -name "*~" -exec rm -rf {} \;

##### find and copy *.ko files(module files)

for module_file in `find $KERNDIR_OUT -name "*.ko"`
do
	echo $module_file
	"$CROSS_COMPILE"strip --strip-unneeded $module_file
	cp $module_file $INITRAM_DIR/lib/modules/
done

##### Compressing ramdisk Directory

cd $INITRAM_DIR
find . | cpio -o -H newc | gzip > $KERNDIR/out_bootimg/ramdisk.cpio.gz

cd $KERNDIR/out_bootimg


##### Make Bootimg

$KERNDIR/mkbootimg --base 0x10000000 --pagesize 2048 --ramdisk_offset 0x01000000 --kernel $KERNDIR_OUT/arch/arm/boot/zImage --ramdisk ramdisk.cpio.gz -o boot.img

if [ -e $KERNDIR/out_bootimg/boot.img ]
then
	echo_info "Build Complete"
else
	echo_error "Couldn't make boot.img"
	exit
fi

if [ "$DEVICE_CARRIER" = "lg" ]
then
	DEVICE_CARRIER=U
fi

$KERNDIR/build_md5.sh ImmortalKernel-140225-`echo $DEVICE_CARRIER | tr -s [:lower:] [:upper:]`-Odin  boot.img
