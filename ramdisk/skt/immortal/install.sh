#!/immortal/bin/busybox sh
PATH=/immortal/bin:$PATH

if [ -e "/system/app/Immortal Kernel.apk" ]; then exit; fi

mount -o rw,remount /system

cp "/immortal/Immortal Kernel.apk" "/system/app/Immortal Kernel.apk"
chmod 644 /system/app/Immortal Kernel.apk
chown root.root /system/app/Immortal Kernel.apk

mount -o ro,remount /system
