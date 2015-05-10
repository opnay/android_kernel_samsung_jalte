#!/res/busybox sh

do_mount() {
	if [ ! -e $2 ]; then
		echo "immortal: mount: create directory: $2"
		mkdir -p $2
	fi
	mount -rw -t ext4 -o nosuid,nodev,noatime,noauto_da_alloc,discard,journal_async_commit,errors=panic $1 $2
	mount -rw -t f2fs -o nosuid,nodev,noatime,discard $1 $2
}

PATH=/res/asset
DEV_SYSTEM=/dev/block/mmcblk0p20
DEV_CACHE=/dev/block/mmcblk0p19
DEV_DATA=/dev/block/mmcblk0p21

mount -o rw,remount rootfs

mount -t ext4 -o nosuid,nodiratime,errors=panic $DEV_SYSTEM /system
mount -t f2fs -o nosuid,errors=panic $DEV_SYSTEM /system

do_mount $DEV_DATA /data
do_mount $DEV_CACHE /cache

touch /dev/block/mount_fs

exit
