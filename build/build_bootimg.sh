source $(dirname $0)/export.sh

RAMDISK=""
BOOTIMG="boot"
isName=false

function help() {
	echo -e "build_bootimg.sh [-o|--out <out_file_name>] <ramdisk name>"
	echo -e "  -o, --out\tSet boot.img file name / default: boot"
	exit
}

for tmp in $@; do
	if $isName; then
		BOOTIMG=$tmp
		isName=false
		continue
	fi
	case $tmp in
		-o | --out) is_name=true;;
		-h | --help) help; exit;;
		*) RAMDISK=$RAMDISK_ORIG/$tmp;;
	esac
done

if [ "$RAMDISK" == "" ]; then
	help
fi

if [ "$RAMDISK_ORIG" == "$RAMDISK" ] || [ ! -e $RAMDISK ]; then
	echo -e "Directory was not found ($RAMDISK)"
	exit
fi

## Copy Ramdisk Directory
if [ ! -e "$KERNEL_OUT" ]; then
	echo "Directory was not found ($KERNEL_OUT)"
	exit
fi

# Regenerate directory
rm -rf $RAMDISK_OUT $KERNEL_BUILD_OUT
mkdir -p $RAMDISK_OUT $KERNEL_BUILD_OUT

# Copy and Clean ramdisk
cp -r $RAMDISK/* $RAMDISK_OUT/
find $RAMDISK_OUT -name EMPTY -exec rm -rf {} \;
find $RAMDISK_OUT -name "*~" -exec rm -rf {} \;

# Copy Module and strip.
mkdir -p $RAMDISK_OUT/lib/modules/
for i in `find $KERNEL_OUT -name "*.ko"`; do
	echo $i
	$strip --strip-unneeded $i
	cp $i $RAMDISK_OUT/lib/modules/
done

# Write Immortal Kernel Version.
echo -e "\nimmortal.version=$IMMORTAL_VERSION" >> $RAMDISK_OUT/default.prop

# get carrier
CA=`sed -n -e 's/^CONFIG_MACH_JA_KOR_\(.\+\)\=y$/\L\1/p' $KERNEL_OUT/.config`

# Rename .carrier files and remove unused file.
for i in `find $RAMDISK_OUT -name "*.$CA"`; do
	mv $i `echo $i | sed -e 's/\.'"$CA"'//'`
done
rm $(find $RAMDISK_OUT -name "*.skt" -o -name "*.kt" -o -name "*.lg")

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

cd $RAMDISK_OUT && $KERNEL_BUILD/ramdisk_fix_permissions.sh && \
    find . | fakeroot cpio -o -H newc > $KERNEL_BUILD_OUT/ramdisk_"$BOOTIMG".cpio
cat $KERNEL_BUILD_OUT/ramdisk_"$BOOTIMG".cpio | $compr > $KERNEL_BUILD_OUT/ramdisk_"$BOOTIMG".cpio.$type

cp $KERNEL_OUT/arch/arm/boot/zImage $KERNEL_BUILD_OUT/zImage

$mkbootimg $mkbootimg_args \
    --kernel $KERNEL_BUILD_OUT/zImage \
    --ramdisk $KERNEL_BUILD_OUT/ramdisk_"$BOOTIMG".cpio.$type \
    -o $KERNEL_BUILD_OUT/$BOOTIMG.img

#### End
