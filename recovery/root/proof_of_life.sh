#!/sbin/sh
dmesg > /tmp/twrp_dmesg.txt

BPATH="/sys/class/backlight/lm3630a_led/brightness"

# Blink backlight 5 times
for i in 1 2 3 4 5; do
if [ -f "$BPATH" ]; then
    echo 100 > "$BPATH"
fi
sleep 0.3
if [ -f "$BPATH" ]; then
    echo 0 > "$BPATH"
fi
sleep 0.3
done

# Leave backlight on steady at 50% for 30s window
if [ -f "$BPATH" ]; then
echo 50 > "$BPATH"
fi

sleep 30
reboot
