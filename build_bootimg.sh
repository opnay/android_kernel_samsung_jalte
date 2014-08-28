#########
# $1 = Ramdisk directory
# $2 = compress < gz / lz4 >
#########
source build_export.sh
source build_function.sh

KERNEL_DIR_BOOTIMG=`pwd`/bootimg
RAMDISK_DIR_ORIG=$1
BOOTIMG=$2

if [ "$RAMDISK_DIR" = "" -o "$COMPRESS" = "" ]; then
	Error "Usage :\nbuild_ramdisk.sh <Ramdisk original directory> <out_file_name>"
	exit
fi

## Copy Ramdisk Directory

if [ ! -e "$KERNEL_DIR_OUT" ]; then
	echo "module file not found"
	exit
fi
# Clean

rm -rf $RAMDISK_DIR $KERNEL_DIR_BOOTIMG
mkdir -p $RAMDISK_DIR $KERNEL_DIR_BOOTIMG

cp -r $RAMDISK_DIR_ORIG/* $RAMDISK_DIR/
find $RAMDISK_DIR -name EMPTY -exec rm -rf {} \;
find $RAMDISK_DIR -name "*~" -exec rm -rf {} \;
# Copy Module and strip.
for i in `find $KERNDIR_DIR -name "*.ko"`; do
	echo $i
	$STRIP --strip-unneeded $i
	cp $i $RAMDISK_DIR/lib/modules/
done
# Write Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_DIR/default.prop

ShowInfo "Compress with" $COMPRESS

$MKBOOTFS $RAMDISK_DIR > $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio

if [ "$COMPRESS" = "gz" ]; then
	gzip -9 < $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio > $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.gz
elif [ "$COMPRESS" = "lz4" ]; then
	lz4c -l -hc stdin $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.lz4 < $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio
fi

cp $KERNEL_DIR_OUT/arch/arm/boot/zImage $KERNEL_DIR_BOOTIMG/zImage

$MKBOOTIMG \
    -o $KERNEL_DIR_BOOTIMG/$BOOTIMG.img
