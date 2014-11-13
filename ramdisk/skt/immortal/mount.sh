#!/res/busybox sh

do_mount() {
	if [ ! -e $2 ]; then
		echo "immortal: mount: create directory: $2"
		mkdir -p $2
	fi
	mount -rw -t ext4 -o nosuid,nodev,noatime,noauto_da_alloc,discard,journal_async_commit,errors=panic $1 $2
	mount -rw -t f2fs -o nosuid,nodev,noatime,discard,errors=panic $1 $2
}

PATH=/res/asset:$PATH
DEV_CACHE=/dev/block/platform/dw_mmc.0/by-name/CACHE
DEV_DATA=/dev/block/platform/dw_mmc.0/by-name/DATA

do_mount $DEV_DATA /data
do_mount $DEV_CACHE /cache

start sdcard

exit
