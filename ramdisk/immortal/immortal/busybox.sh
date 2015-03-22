#!/res/busybox sh

BUSYBOX=/res/busybox

$BUSYBOX mount -o rw,remount /
$BUSYBOX mkdir -p /res/asset

for i in `/res/busybox --list`; do
  $BUSYBOX ln -s $BUSYBOX /res/asset/$i
done
