#!/res/busybox sh
PATH=/res/asset:$PATH

# Wait for mount system
while [[ "$(mount | grep '/system')" == "" || "$(mount | grep '/data')" == "" ]]; do
	echo "Not mount /system and /data"
	sleep 1
done

if [ ! -e "/data/media/0/immortal/install" ]; then exit; fi

if [ -e "/system/app/ImmortalKernel.apk" ]; then exit; fi


mount -o rw,remount /system

cp -f "/immortal/ImmortalKernel.apk" "/system/app/"
chmod 644 /system/app/ImmortalKernel.apk
chown root.root /system/app/ImmortalKernel.apk

mount -o ro,remount /system

exit
