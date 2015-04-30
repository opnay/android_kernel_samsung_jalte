#########
# $1 = Ramdisk directory
# $2 = compress < gz / lz4 >
#########
source build_export.sh

KERNEL_OUT_BOOTIMG=`pwd`/bootimg
RAMDISK_DIR_ORIG=""
BOOTIMG="boot"
is_name=false

function help() {
	echo -e "build_bootimg.sh [-o|--out <out_file_name>] <ramdisk directory>"
	echo -e "  -o, --out\tSet boot.img file name(without .img) default: boot"
	exit
}

for tmp in $@; do
	if $is_name; then
		BOOTIMG=$tmp
		is_name=false
		continue
	fi
	case $tmp in
		-o | --out) is_name=true;;
		*) RAMDISK_DIR_ORIG=$tmp;;
	esac
done

if [ '$RAMDISK_DIR_ORIG' == '' ] || [ ! -e $RAMDISK_DIR_ORIG ]; then
	echo -e "Directory was not found ($RAMDISK_DIR_ORIG)"
	exit
fi

## Copy Ramdisk Directory
if [ ! -e "$KERNEL_OUT" ]; then
	echo "Directory was not found ($KERNEL_OUT)"
	exit
fi

# Regenerate directory
rm -rf $RAMDISK_DIR $KERNEL_OUT_BOOTIMG
mkdir -p $RAMDISK_DIR $KERNEL_OUT_BOOTIMG

# Copy and Clean ramdisk
cp -r $RAMDISK_DIR_ORIG/* $RAMDISK_DIR/
find $RAMDISK_DIR -name EMPTY -exec rm -rf {} \;
find $RAMDISK_DIR -name "*~" -exec rm -rf {} \;
# Copy Module and strip.
for i in `find $KERNEL_OUT -name "*.ko"`; do
	echo $i
	$strip --strip-unneeded $i
	cp $i $RAMDISK_DIR/lib/modules/
done
# Write Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_DIR/default.prop

if [ $(find $RAMDISK_DIR -name "*.skt") ]; then
for i in "$(cat out/.config | grep CONFIG_MACH_JA_)"; do
	if [ "$(echo $i | grep _SKT)" ]; then
		mv $RAMDISK_DIR/init.rilcarrier.skt.rc $RAMDISK_DIR/init.rilcarrier.rc
		mv $RAMDISK_DIR/sepolicy_version.skt $RAMDISK_DIR/sepolicy_version
		rm $(find $RAMDISK_DIR -name "*lg*") $(find $RAMDISK_DIR -name "*kt*")
	elif [ "$(echo $i | grep _KT)" ]; then
		mv $RAMDISK_DIR/init.rilcarrier.kt.rc $RAMDISK_DIR/init.rilcarrier.rc
		mv $RAMDISK_DIR/sepolicy_version.kt $RAMDISK_DIR/sepolicy_version
		rm $(find $RAMDISK_DIR -name "*skt*") $(find $RAMDISK_DIR -name "*lg*")
	elif [ "$(echo $i | grep _LGT)" ]; then
		mv $RAMDISK_DIR/init.rilcarrier.lg.rc $RAMDISK_DIR/init.rilcarrier.rc
		mv $RAMDISK_DIR/sepolicy_version.lg $RAMDISK_DIR/sepolicy_version
		rm $(find $RAMDISK_DIR -name "*skt*") $(find $RAMDISK_DIR -name "*kt*")
	fi
done
fi


if [ ! $(cat $KERNEL_OUT/.config | grep "CONFIG_RD_GZIP=y") = "" ]; then
	type="gz"
	comp="gzip -n -9 -f"
elif [ ! $(cat $KERNEL_OUT/.config | grep "CONFIG_RD_GZIP=y") = "" ]; then
	type="lz4"
	comp="lz4c -l -hc -f"
fi

$mkbootfs $RAMDISK_DIR > $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio
cat $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio | $comp > $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio.$type

cp $KERNEL_OUT/arch/arm/boot/zImage $KERNEL_OUT_BOOTIMG/zImage

$mkbootimg $mkbootimg_args \
    --kernel $KERNEL_OUT_BOOTIMG/zImage \
    --ramdisk $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio.$type \
    -o $KERNEL_OUT_BOOTIMG/$BOOTIMG.img

#### End
