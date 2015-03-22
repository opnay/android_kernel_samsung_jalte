## Check adb.
## If you have sdk, set adb command line
#ADB=/your/adb/path
adb="$(which adb)"
adb_wait="$adb wait-for-device"
adb_push="$adb push"
adb_shell="$adb shell"
adb_reboot="$adb reboot"

# boot.img binary
BOOTIMG=$1
DEVPATH=/dev/block/mmcblk0p9

if [ "$BOOTIMG" == "" ]; then
	echo -e "Usage : build_install.sh <boot.img path>"
	echo -e "ex)" "build_install.sh boot.img"
	exit
fi

echo -e "ADB : $adb"
if [ ! -e $adb ] || [ "$adb" == "" ]; then
	echo -e "adb Not Found!!!"
	exit
fi

echo -e "BOOTIMG : $BOOTIMG"
if [ ! -e $BOOTIMG ]; then
	echo -e "boot.img Not Found!!!"
	exit
fi

echo -e " * Wait for device"
$adb_wait

echo -e " * Push boot.img to device (in /sdcard)"
$adb_push $BOOTIMG /sdcard/boot.img

echo -e " * Install..."
$adb_shell dd if=/sdcard/boot.img of=$DEVPATH
echo -e " * Reboot!"
$adb_reboot

echo -e " * Finish Install"
