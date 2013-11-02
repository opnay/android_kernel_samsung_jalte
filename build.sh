export ARCH=arm
export CROSS_COMPILE=/home/diadust/toolchain/android-toolchain-eabi-4.8-13.09/bin/arm-eabi-
KERNDIR=/home/diadust/project/jalte
INITRAM_DIR=$KERNDIR/initramfs
JOBN=16

if [  "$1" == "skt" ]
then
INITRAM_ORIG=/home/diadust/android/firmware/skt/MJC
else if [ "$1" == "kt" ]
then
INITRAM_ORIG=/home/diadust/android/firmware/kt/MH2
else if [ "$1" == "lg" ]
then
INITRAM_ORIG=/home/diadust/android/firmware/lg/MH1
else
        echo "No defined"
        echo "./build.sh [ skt / kt / lg ]"
        exit 1
fi fi fi

echo "Check your Init Directory : $INITRAM_ORIG"
if [ -e $INITRAM_ORIG ]
then
        echo "Initramdisk is exist"
else
        echo "No such directory"
        exit 1
fi

DEFCONFIGS=immortal_"$1"_defconfig
if [[ ! -e "$KERNDIR/arch/arm/configs/$DEFCONFIGS" ]]
then
        echo "Configuration file $DEFCONFIGS don't exists"
        exit 1
fi

echo "----------------------------------------------------------------------------------------------------------CLEAN"
rm -Rf $KERNDIR/bootimg $INITRAM_DIR $KERNDIR/out
mkdir $KERNDIR/bootimg $INITRAM_DIR $KERNDIR/out
cp -R $INITRAM_ORIG/* $INITRAM_DIR/
echo "----------------------------------------------------------------------------------------------------------CONFIG"
make $DEFCONFIGS O=$KERNDIR/out
make menuconfig O=$KERNDIR/out
echo "----------------------------------------------------------------------------------------------------------BUILD"
make -j$JOBN O=$KERNDIR/out
echo "----------------------------------------------------------------------------------------------------------MODULES"
rm $INITRAM_DIR/lib/modules/*
find . -name "*.ko" -exec echo {} \;
find . -name "*.ko" -exec cp {} $INITRAM_DIR/lib/modules/  \;

echo "----------------------------------------------------------------------------------------------------------BOOTIMG"
cd $INITRAM_DIR
find . | cpio -o -H newc | gzip > $KERNDIR/bootimg/ramdisk.cpio.gz
cd $KERNDIR/bootimg
$KERNDIR/mkbootimg --cmdline console=ttySAC2,115200n8 vmalloc=512M androidboot.console=ttySAC2 --base 0x10000000 --pagesize 2048 --kernel $KERNDIR/out/arch/arm/boot/zImage --ramdisk ramdisk.cpio.gz --output "$1"_boot.img
echo " Build Complete "

