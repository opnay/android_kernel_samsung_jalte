source $(dirname $0)/export.sh

if [ $# != 2 -o "$1" == "" -o "$2" == "" ]; then
	echo "Usage : build_flashzip.sh <output file name> <boot.img file>"
	exit
fi

_zipalign=$(which zipalign)

output=$1
bootimg=$2
carrier=`sed -n -e 's/^CONFIG_MACH_JA_KOR_\(.\+\)\=y$/\L\1/p' $KERNEL_OUT/.config`

if ! [ -e $bootimg ]; then
	echo -e "Error: No such file or directory \"$bootimg\""
	exit
fi

mkdir -p $KERNEL_BUILD_OUT/tmp
cp -r $KERNEL_BUILD/flashzip/META-INF $KERNEL_BUILD_OUT/tmp
cat << EOF > $KERNEL_BUILD_OUT/tmp/META-INF/com/google/android/updater-script
ui_print("Galaxy S4 LTE");
ui_print("      Immortal Kernel $IMMORTAL_VERSION");
ui_print("      for $carrier");
ui_print("===============================");
ui_print("");
ui_print("- Flashing boot.img");
package_extract_file("boot.img","/dev/block/mmcblk0p9");
ui_print("");
ui_print("- Finished");
EOF

cp $bootimg $KERNEL_BUILD_OUT/tmp/boot.img
cd $KERNEL_BUILD_OUT/tmp
zip -r $output.zip META-INF boot.img
zipalign -f -v 4 $output.zip $KERNEL_BUILD_OUT/$output.zip
rm -rf $KERNEL_BUILD_OUT/tmp

