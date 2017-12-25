source $(dirname $0)/export.sh

RAMDISK=""
RAM_FILE="ramdisk.cpio"
OUT_FILE="boot.img"

function help() {
	echo -e "build_bootimg.sh <ramdisk name>"
	exit
}

for tmp in $@; do
	case $tmp in
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
mkdir -p $KERNEL_BUILD_OUT/usr
cp $KERNEL_OUT/usr/gen_init_cpio $KERNEL_BUILD_OUT/usr/gen_init_cpio

# Copy and Clean ramdisk
cp -r $RAMDISK $RAMDISK_OUT/
find $RAMDISK_OUT -name EMPTY -exec rm -rf {} \;

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
ca=`sed -n -e 's/^CONFIG_MACH_JA_KOR_\(.\+\)\=y$/\L\1/p' $KERNEL_OUT/.config`

# Rename .carrier files and remove unused file.
for i in `find $RAMDISK_OUT -name "*.$ca"`; do
	mv $i `echo $i | sed -e 's/\.'"$ca"'//'`
done
rm $(find $RAMDISK_OUT -name "*.skt" -o -name "*.kt" -o -name "*.lg")

type=`sed -n -e 's/^CONFIG_RD_\(.\+\)\=y$/\L\1/p' $KERNEL_OUT/.config`
if [ '$type' != '' ]; then
	RAM_FILE=$RAM_FILE.$type
fi

cd $RAMDISK_OUT && $KERNEL_BUILD/ramdisk_fix_permissions.sh
cd $KERNEL_BUILD_OUT && fakeroot sh $KERNEL_DIR/scripts/gen_initramfs_list.sh -o $RAM_FILE $RAMDISK_OUT

cp $KERNEL_OUT/arch/arm/boot/zImage $KERNEL_BUILD_OUT/zImage

cd $KERNEL_BUILD_OUT
$mkbootimg $mkbootimg_args \
    --kernel zImage \
    --ramdisk $RAM_FILE \
    -o $OUT_FILE

#### End
