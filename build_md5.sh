# usage : build_md5.sh <output file name> <compressing files>...
# this script will make Odin Package (<output>.tar.md5)

source build_function.sh

if [ $# != 2 -o "$1" == "" -o "$2" == "" ]; then
	Error "Usage : build_md5.sh <output filename> <compressing files>..."
	ShowInfo "ex)" "build_md5.sh firmware boot.img system.img"
	exit
fi

echo -e "\e[33mMake Odin Package \e[00m"

output=$1
for names in $@; do
	if [ "$names" != "$output" ]
	then
		if [ ! -e $names ]
		then
			echo "Error: No such file or directory \"$names\""
			exit
		fi
		compfiles="$compfiles $names"
	fi
done

echo "-Compressing files"
tar -H ustar -c $compfiles > $output.tar

echo "-Write md5 checksum"
md5sum -t $output.tar >> $output.tar

echo "-Rename .tar to .tar.md5"
mv $output.tar $output.tar.md5

echo -e "\e[33mComplete $output.tar.md5 \e[00m"
