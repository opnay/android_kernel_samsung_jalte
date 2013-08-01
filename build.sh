export ARCH=arm
export CROSS_COMPILE=/home/diadust/android/toolchain/android-toolchain-eabi-4.7/bin/arm-eabi-
KERNDIR=/home/diadust/project/kernel_e300s
INITRAM_DIR=$KERNDIR/initramfs
JOBN=16
export CONFIG_DEBUG_SECTION_MISMATCH=y


if [  "$1"="skt" -o "$1"="ktt" ]
then
INITRAM_ORIG=/home/diadust/GalaxyS4/$1/MG2/boot
DEFCONFIGS=immortal_"$1"_defconfig
	if [[ ! -e "$KERNDIR/arch/arm/configs/$DEFCONFIGS" ]]
	then
		echo "Configuration file $DEFCONFIGS don't exists"
		exit 1
	fi
else
	echo "No defined"
	echo "./build.sh [ skt / ktt ]"
	exit 1
fi


echo "----------------------------------------------------------------------------------------------------------CLEAN"
rm $KERNDIR/mkbootimg/zImage
rm $KERNDIR/mkbootimg/ramdisk.cpio.gz
mv $KERNDIR/mkbootimg/boot.img $KERNDIR/mkbootimg/boot.img.bak
rm -Rf $INITRAM_DIR
mkdir $INITRAM_DIR
cp -R $INITRAM_ORIG/* $INITRAM_DIR/
find $INITRAM_DIR -name "*~" -exec rm -f {} \;
make distclean
echo "----------------------------------------------------------------------------------------------------------CONFIG"
make $DEFCONFIGS
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

