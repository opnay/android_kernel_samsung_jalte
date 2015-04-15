## Check adb.
## If you have sdk, set adb command line
#ADB=/your/adb/path
adb="$(which adb)"
adb_wait="$adb wait-for-device"
adb_push="$adb push"
adb_shell="$adb shell"
adb_reboot="$adb reboot"

# boot.img binary
DEVPATH=/dev/block/mmcblk0p9

function help() {
	echo -e "install.sh [-s|--su] [-h|--help] <boot.img>\n"
	echo -e "  -s, --su\tRun shell with su"
	echo -e "  -h, --help\tShow this help message"
	exit
}

if [[ "$@" == "" ]]; then
	help
fi

for tmp in $@; do
	case $tmp in
		-s | --su) adb_shell="$adb_shell su -c";;
		-h | --help) help;;
		*) BOOTIMG=$tmp;;
	esac
done

echo -e "ADB : $adb"
if [ ! -e $adb ] || [ "$adb" == "" ]; then
	echo -e "adb was not found"
	exit
fi

echo -e "BOOTIMG : $BOOTIMG"
if [ ! -e $BOOTIMG ] || [ "$BOOTIMG" = "" ]; then
	echo -e "boot.img was not found"
	exit
fi

echo -e " * Wait for device"
$adb_wait

echo -e " * Push boot.img to device (in /sdcard)"
$adb_push $BOOTIMG /data/local/tmp/boot.img

echo -e " * Install..."
$adb_shell dd if=/data/local/tmp/boot.img of=$DEVPATH

echo -e " * Reboot!"
$adb_reboot

echo -e " * Finish Install"
