## Check adb.
## If you have sdk, set adb command line
#ADB=/your/adb/path
adb="$(which adb)"
adb_shell="$adb shell"

# boot.img binary
DEVPATH=/dev/block/mmcblk0p9

function help() {
	echo -e "install.sh [--heimdall] [-s|--su] [-h|--help] <boot.img>\n"
	echo -e "  --heimdall\tFlash with heimdall"
	echo -e "  -s, --su\tRun shell with su"
	echo -e "  -r\tInstall to Recovery partition(Default: /dev/block/platform/dw_mmc.0/by-name/RECOVERY)"
	echo -e "  -h, --help\tShow this help message"
	exit
}

if [[ "$@" == "" ]]; then
	help
fi

for tmp in $@; do
	case $tmp in
	    --heimdall) use_heimdall=true;;
		-s | --su) adb_shell="$adb_shell su -c";;
		-r) DEVPATH=/dev/block/platform/dw_mmc.0/by-name/RECOVERY && adb_reboot="$adb_reboot recovery";;
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
if [ -d $BOOTIMG ] || [ ! -e $BOOTIMG ] || [ "$BOOTIMG" = "" ]; then
	echo -e "boot.img was not found!!"
	exit
fi

if [ "$use_heimdall" == "true" ]; then
	echo ""
	echo "# Wait for reboot device."
	echo "# If it does not work,"
	echo "#   Check enable 'USB Debugging' on your device."
	echo ""
	$adb wait-for-device && $adb reboot download
	echo ""
	echo "# Adb disconnected!"
	echo "# Now, wait 5sec for download mode"
	echo ""
	sleep 5
    heimdall flash --BOOT $BOOTIMG
	echo "# done!"
else
	echo -e "* Start adb server"
	$adb start-server

	echo -e "* Wait for device"
	$adb wait-for-device

	echo -e "* Push boot.img to device (in /data/local/tmp)"
	$adb push $BOOTIMG /data/local/tmp/boot.img

	echo -e "* Install..."
	echo -e "*   Cleanup dev"
	$adb_shell dd if=/dev/zero of=$DEVPATH
	echo -e "*   Flashing boot.img"
	$adb_shell dd if=/data/local/tmp/boot.img of=$DEVPATH

	echo -e "* Reboot!"
	$adb reboot

	echo -e "* Finish Install"
fi
