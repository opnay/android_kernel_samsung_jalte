on fs
# GPS
    chown root system /dev/ttySAC1
    chmod 0660 /dev/ttySAC1
    chown root system /sys/class/sec/gps/GPS_PWR_EN/value
    chmod 0664 /sys/class/sec/gps/GPS_PWR_EN/value
    mkdir /data/system 0771 system system
    chown system system /data/system
    mkdir /data/system/gps 0771 system system
    chown system system /data/system/gps
    rm /data/gps_started
    rm /data/glonass_started
    rm /data/smd_started
    rm /data/sv_cno.info

service cpboot-daemon /sbin/cbd -d -t ss222 -b s -m c -p 13
    class main
    user root
    group radio cache inet misc audio sdcard_rw log sdcard_r shell
    seclabel u:r:cbd:s0

# GPS
service gpsd /system/bin/gpsd -c /system/etc/gps.xml
    class main
    user gps
    group system inet net_raw
    ioprio be 0
