export ARCH=arm
export CROSS_COMPILE=/home/op_nay/Android/toolchain/android-toolchain-eabi-4.8-13.11/bin/arm-eabi-
#get kernel directory(current directory) from terminal
KERNDIR=`pwd`
KERNDIR_OUT=$KERNDIR/out
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

#Build function
function build_clean() {
	#Cean directory
	rm -rf $KERNDIR/out_bootimg $KERNDIR_OUT
	mkdir $KERNDIR/out_bootimg $KERNDIR_OUT $INITRAM_DIR

	#Clean objects
	#is not used
	#make distclean
}

function build_defconfig() {
	make $1 menuconfig O=$KERNDIR_OUT
}

function build_initramfs() {
	# copy original initramfs directory to kernel directory
	cp -r $1/* $INITRAM_DIR/
	# remove backup files
	find $INITRAM_DIR -name "*~" -exec rm -rf {} \;

	# find and copy modulized files
	for module_file in `find $KERNDIR_OUT -name "*.ko"`
	do
		echo $module_file
		cp $module_file $INITRAM_DIR/lib/modules/
	done
	# make initramfs file
	cd $INITRAM_DIR
	find . | cpio -o -H newc | gzip > $KERNDIR/out_bootimg/ramdisk.cpio.gz
}

function build_bootimg() {
	cd $KERNDIR/out_bootimg
	$KERNDIR/mkbootimg --base 0x10000000 --pagesize 2048 --kernel $KERNDIR_OUT/arch/arm/boot/zImage --ramdisk ramdisk.cpio.gz --output "$1"_boot.img
}

if [ "$1" == "" -o "$2" == "" ]
then
	echo_error "build.sh [ skt / kt / lg ] [ Your initram directory ]"
	echo_error "Initramfs directory will be set \"/<Your initram>/<skt / kt / lg>\""
	echo_info "\nexample: build.sh skt /home/test/initram"
	echo_info "will set /home/test/initram/skt"
	exit
else
	INITRAM_ORIG="$2/$1"
fi

echo_info "Check your Init Directory : $INITRAM_ORIG"
if [ -e $INITRAM_ORIG ]
then
        echo_info "Ramdisk is exist"
else
        echo_error "No such directory"
        exit 1
fi

defconfig=immortal_"$1"_defconfig
if [ ! -e "$KERNDIR/arch/arm/configs/$defconfig" ]
then
        echo_error "Configuration file $defconfig don't exists"
        exit 1
fi


echo_notify "----------------------------------------------------------------------------------------------------------CLEAN"
build_clean
echo_notify "----------------------------------------------------------------------------------------------------------CONFIG"
build_defconfig $defconfig
echo_notify "----------------------------------------------------------------------------------------------------------BUILD"
make -j$jobn O=$KERNDIR_OUT

if [ ! -e $KERNDIR_OUT/arch/arm/boot/zImage ]
then
	echo_error "Error occured"
	exit
fi
echo_notify "----------------------------------------------------------------------------------------------------------INITRAMFS"
build_initramfs $INITRAM_ORIG
echo_notify "----------------------------------------------------------------------------------------------------------BOOTIMG"
build_bootimg "$1"
if [ -e $KERNDIR/out_bootimg/"$1"_boot.img ]
then
	echo_info "Build Complete"
else
	echo_error "Couldn't make boot.img"
	exit
fi
