#########
# $1 = Ramdisk directory
# $2 = compress < gz / lz4 >
#########
source build_function.sh

KERNEL_BOOTIMG_DIR=`pwd`/bootimg
RAMDISK_DIR=$1
COMPRESS=$2

if [ "$RAMDISK_DIR" = "" -o "$COMPRESS" = "" ]; then
	Error "Usage : build_ramdisk.sh <Ramdisk directory> <compress (gz / lz4)>"
	exit
fi

ShowInfo "Compress with" $COMPRESS

./bin/mkbootfs $RAMDISK_DIR > $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio

if [ "$COMPRESS" = "gz" ]; then
	gzip -9 < $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio > $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.gz
elif [ "$COMPRESS" = "lz4" ]; then
	lz4c -l -hc stdin $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio.lz4 < $KERNEL_BOOTIMG_DIR/ramdisk-boot.cpio
fi

