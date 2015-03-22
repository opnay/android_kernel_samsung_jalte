#########
# $1 = Ramdisk directory
# $2 = compress < gz / lz4 >
#########
source build_export.sh

KERNEL_DIR_BOOTIMG=`pwd`/bootimg
RAMDISK_DIR_ORIG=$1
BOOTIMG=$2

if [ $# != 2 -o "$RAMDISK_DIR" = "" -o "$COMPRESS" = "" ]; then
	echo -e "Usage : build_ramdisk.sh <Ramdisk original directory> <out_file_name>"
	echo -e "ex)" "build_bootimg.sh ramdisk/skt boot"
	exit
fi

## Copy Ramdisk Directory
if [ ! -e "$KERNEL_DIR_OUT" ]; then
	echo "out directory was not found"
	exit
fi

# Regenerate directory
rm -rf $RAMDISK_DIR $KERNEL_DIR_BOOTIMG
mkdir -p $RAMDISK_DIR $KERNEL_DIR_BOOTIMG

# Copy and Clean ramdisk
cp -r $RAMDISK_DIR_ORIG/* $RAMDISK_DIR/
find $RAMDISK_DIR -name EMPTY -exec rm -rf {} \;
find $RAMDISK_DIR -name "*~" -exec rm -rf {} \;
# Copy Module and strip.
for i in `find $KERNEL_DIR_OUT -name "*.ko"`; do
	echo $i
	$STRIP --strip-unneeded $i
	cp $i $RAMDISK_DIR/lib/modules/
done
# Write Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_DIR/default.prop

echo -e "Compress with" $COMPRESS

$MKBOOTFS $RAMDISK_DIR > $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio

if [ "$COMPRESS" = "gz" ]; then
	cat $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio | gzip -n -9 -f > $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.gz
elif [ "$COMPRESS" = "lz4" ]; then
	cat $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio | lz4c -l -hc -f > $KERNEL_DIR_BOOTIMG/ramdisk-boot.cpio.lz4
fi

cp $KERNEL_DIR_OUT/arch/arm/boot/zImage $KERNEL_DIR_BOOTIMG/zImage

$mkbootimg $mkbootimg_args\
    -o $KERNEL_DIR_BOOTIMG/$BOOTIMG.img

#### End
