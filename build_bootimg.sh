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
mkdir -p $RAMDISK_DIR/lib/modules/
for i in `find $KERNEL_OUT -name "*.ko"`; do
	echo $i
	$strip --strip-unneeded $i
	cp $i $RAMDISK_DIR/lib/modules/
done
# Write Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_DIR/default.prop

# get carrier
CA=`sed -n -e 's/^CONFIG_MACH_JA_KOR_\(.\+\)\=y$/\L\1/p' $KERNEL_OUT/.config`
# Rename .carrier files and remove unused file.
for i in `find $RAMDISK_DIR -name "*.$CA"`; do
	mv $i `echo $i | sed -e 's/\.'"$CA"'//'`
done
rm $(find $RAMDISK_DIR -name "*.skt" -o -name "*.kt" -o -name "*.lg")

type=`find $KERNEL_OUT/usr -name "initramfs_data.cpio*" | sed -n -e 's/^.\+\.cpio\.\(.\+\)$/\1/p'`

case $type in
	gz) compr="gzip -n -9 -f";;
	bz2) compr="bzip2 -9 -f";;
	lzma) compr="lzma -9 -f";;
	xz) compr="xz --check=crc32 --lzma2=dict=1MiB";;
	lzo) compr="lzop -9 -f";;
	lz4) compr="lz4 -l -9 -f";;
	*) compr="cat";;
esac

sh -c "cd "$RAMDISK_DIR" && "$KERNEL_DIR"/ramdisk_fix_permissions.sh && \
    find . | fakeroot cpio -o -H newc" > $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio
cat $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio | $compr > $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio.$type

cp $KERNEL_OUT/arch/arm/boot/zImage $KERNEL_OUT_BOOTIMG/zImage

$mkbootimg $mkbootimg_args \
    --kernel $KERNEL_OUT_BOOTIMG/zImage \
    --ramdisk $KERNEL_OUT_BOOTIMG/ramdisk-boot.cpio.$type \
    -o $KERNEL_OUT_BOOTIMG/$BOOTIMG.img

#### End
