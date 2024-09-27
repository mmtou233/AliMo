#!/system/bin/sh

MODDIR=${0%/*}
MODDIR_C="/data/adb/AliMo"
export PATH=/debug_ramdisk/.magisk/busybox:$PATH

if [ -z "$(pgrep alist)" ]; then
    if [ -f "$MODDIR_C/bin/alist" ]; then
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到 alist 终止，正在重新启动。。。" >> "${MODDIR_C}/log.txt"
        $MODDIR_C/bin/alist server --data "${MODDIR_C}/data" >> /dev/null 2>&1 &
        if [ -z "$(pgrep alist)" ]; then
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 重启进程失败" >> "${MODDIR_C}/log.txt"
        else
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 重启进程完毕" >> "${MODDIR_C}/log.txt"
        fi
    else
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 等待 alist 完成下载。。。" >> "${MODDIR_C}/log.txt"
    fi
#else
    #echo "[$(date "+%Y-%m-%d %H:%M:%S")] alist 正常运行中。。。pid：$(pgrep alist)" >> "${MODDIR_C}/log.txt"
fi