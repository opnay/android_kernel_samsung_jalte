#!/res/busybox sh

PATH=/res/asset

# Turn off cores
echo 0 > /sys/devices/system/cpu/cpu1/online
echo 0 > /sys/devices/system/cpu/cpu2/online
echo 0 > /sys/devices/system/cpu/cpu3/online

# MAX 500Mhz (CA7 1Ghz) / powersave
echo "500000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set display brightness
echo "100" > /sys/class/backlight/panel/brightness
