export ARCH=arm
export CROSS_COMPILE=/home/diadust/android/toolchain/android-toolchain-eabi-4.7/bin/arm-eabi-
KERNDIR=/home/diadust/E300S/Kernel
INITRAM_DIR=$KERNDIR/initramfs
INITRAM_ORIG=/home/diadust/E300S/firmware/ME7/boot
JOBN=16
export CONFIG_DEBUG_SECTION_MISMATCH=y


if [[ -z $1 ]]
then
	echo "No configuration file defined"
	exit 1

else 
	if [[ ! -e "$KERNDIR/arch/arm/configs/$1" ]]
	then
		echo "Configuration file $1 don't exists"
		exit 1
	fi
fi

echo "----------------------------------------------------------------------------------------------------------CLEAN"
rm $KERNDIR/mkbootimg/zImage
rm $KERNDIR/mkbootimg/ramdisk.cpio.gz
mv $KERNDIR/mkbootimg/boot.img $KERNDIR/mkbootimg/boot.img.bak
rm -R $INITRAM_DIR/*
cp -R $INITRAM_ORIG/* $INITRAM_DIR/
find $INITRAM_DIR -name "*~" -exec rm -f {} \;
make distclean
echo "----------------------------------------------------------------------------------------------------------CONFIG"
make $1
make menuconfig
echo "----------------------------------------------------------------------------------------------------------BUILD"
make -j$JOBN
echo "----------------------------------------------------------------------------------------------------------MODULES"
find . -name "*.ko" -exec echo {} \;
find . -name "*.ko" -exec cp {} $INITRAM_DIR/lib/modules/  \;

cp $KERNDIR/arch/arm/boot/zImage $KERNDIR/mkbootimg/zImage

echo "----------------------------------------------------------------------------------------------------------BOOTIMG"
cd $INITRAM_DIR
find . | cpio -o -H newc | gzip > $KERNDIR/mkbootimg/ramdisk.cpio.gz
cd $KERNDIR/mkbootimg
./mkbootimg --base 10000000 --pagesize 2048 --kernel zImage --ramdisk ramdisk.cpio.gz -o boot.img
echo " Build Complete "

