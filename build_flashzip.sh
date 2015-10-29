# usage : build_flashzip.sh <output file name> <boot.img file>

source build_export.sh

if [ $# != 2 -o "$1" == "" -o "$2" == "" ]; then
	echo "Usage : build_flashzip.sh <output file name> <boot.img file>"
	exit
fi

_zipalign=$(which zipalign)

output=$1
bootimg=$2
carrier=`grep "CONFIG_MACH_JA_" $KERNEL_OUT/.config | sed -n -e 's/^CONFIG_MACH_JA_KOR_\(.\+\)\=y$/\L\1/p'`

if ! [ -e $bootimg ]; then
	echo -e "Error: No such file or directory \"$bootimg\""
	exit
fi

mkdir -p $KERNEL_OUT_FLASHZIP
cp -r flashzip/* $KERNEL_OUT_FLASHZIP
sed -i -e 's/vX.XX/'$IMMORTAL_VERSION'/g' \
	-e 's/for XX/for '$carrier'/g' \
	$(find $KERNEL_OUT_FLASHZIP -name "updater-script")


cp $bootimg $KERNEL_OUT_FLASHZIP/boot.img
cd $KERNEL_OUT_FLASHZIP
zip -r $output.zip META-INF boot.img
zipalign -f -v 4 $output.zip $KERNEL_DIR/$output.zip
rm -rf $KERNEL_OUT_FLASHZIP
