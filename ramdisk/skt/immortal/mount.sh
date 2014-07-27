#!/immortal/bin/busybox sh

do_mount() {
	if [ ! -e $2 ]; then
		echo "immortal: mount: create directory: $2"
		mkdir -p $2
	fi
	mount -rw -t ext4 -o nosuid,nodev,noatime,noauto_da_alloc,discard,journal_async_commit,errors=panic $1 $2
	mount -rw -t f2fs -o nosuid,nodev,noatime,discard $1 $2
}

PATH=/immortal/bin:$PATH
CACHE_BLOCK=mmcblk0p19
DATA_BLOCK=mmcblk0p21

do_mount /dev/block/$DATA_BLOCK /data
do_mount /dev/block/$CACHE_BLOCK /cache

start sdcard

exit
