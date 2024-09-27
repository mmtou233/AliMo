#!/system/bin/sh

ui_print "********************"

#免重启运行

BUSYBOX_PATH="/data/adb/magisk/busybox:/data/adb/ksu/bin/busybox:/data/adb/ap/bin/busybox"
BUSYBOX=""
for path in $(echo "$BUSYBOX_PATH" | tr ":" "\n"); do
        if [ -f "$path" ]; then
            BUSYBOX="$path"
            break
        fi
    done

$BUSYBOX sh $MODPATH/service.sh &

ui_print "********************"
