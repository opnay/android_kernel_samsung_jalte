#!/res/busybox sh
PATH=/res/asset:$PATH

# Run KSM
echo 1 > /sys/kernel/mm/ksm/run

