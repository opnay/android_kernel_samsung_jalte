#!/res/busybox sh
PATH=/res/asset

mount -t ext4 -o nosuid,nodev,noatime,nodiratime,noauto_da_alloc,discard,journal_async_commit /dev/block/mmcblk0p19 /cache
mount -t f2fs -o nosuid,nodev,noatime,nodiratime,discard /dev/block/mmcblk0p19 /cache
mount -t ext4 -o nosuid,nodev,noatime,nodiratime,noauto_da_alloc,discard,journal_async_commit /dev/block/mmcblk0p21 /data
mount -t f2fs -o nosuid,nodev,noatime,nodiratime,discard /dev/block/mmcblk0p21 /data

touch /dev/.mounted