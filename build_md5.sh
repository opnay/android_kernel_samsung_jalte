# usage : build_md5.sh <output file name> <compressing files>...
# this script will make Odin Package (<output>.tar.md5)

if [ $# != 2 -o "$1" == "" -o "$2" == "" ]; then
	echo "Usage : build_md5.sh <output filename> <compressing files>..."
	exit
fi

echo "Make Odin Package"

output=$1
for names in $@; do
	if [ "$names" != "$output" ]; then
		if [ ! -e $names ]; then
			echo -e "Error: No such file or directory \"$names\""
			exit
		fi
		files="$files $names"
	fi
done

echo " * Compressing files"
tar -H ustar -c $files > $output.tar

echo " * Write md5 checksum"
md5sum -t $output.tar >> $output.tar

echo " * Rename .tar to .tar.md5"
mv $output.tar $output.tar.md5

echo "Complete $output.tar.md5"
