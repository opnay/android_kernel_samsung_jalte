source build_function.sh

## Check adb.
## If you have sdk, set adb command line
#ADB=/your/adb/path
ADB=`which adb`

# boot.img binary
BOOTIMG=$1
DEVPATH=$2
if [ $# != 2 -o "$BOOTIMG" == "" -o "$DEVPATH" == "" ]; then
	Error "Usage : build_install.sh <boot.img path> <install device partition>"
	ShowInfo "ex)" "build_install.sh boot.img /dev/block/mmcblk0p1"
	exit
fi

ShowInfo "ADB:" $ADB
if [ ! -e $ADB ] || [ "$ADB" == "" ]; then
	Error "adb Not Found!!!"
	exit
fi

ShowInfo "BOOTIMG:" $BOOTIMG
if [ ! -e $BOOTIMG ]; then
	Error "boot.img Not Found!!!"
	exit
fi

ShowNoty "Wait for device"
$ADB wait-for-device

ShowNoty "Push boot.img"
$ADB push $BOOTIMG /sdcard/boot.img

ShowNoty "Install..."
$ADB shell su -c dd if=/sdcard/boot.img of=$DEVPATH
ShowNoty "Reboot!"
$ADB reboot

ShowNoty "Finish Install"
