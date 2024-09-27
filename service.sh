#!/system/bin/sh

# 获取绝对路径目录
MODDIR=${0%/*}
MODDIR_C="/data/adb/AliMo"
export PATH=/debug_ramdisk/.magisk/busybox:$PATH

if [ ! -d ${MODDIR_C} ]; then
    mkdir ${MODDIR_C}
fi

#echo "环境变量：$PATH" >> "${MODDIR_C}/log.txt"
echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已获取绝对路径地址：${MODDIR}" >> "${MODDIR_C}/log.txt"

# 为 alist 二进制文件授予可执行权限
chmod 755 $MODDIR/openssl
if [ ! -e "/debug_ramdisk/.magisk/busybox/openssl" ]; then
    ln -s $MODDIR/openssl /debug_ramdisk/.magisk/busybox
fi
if [ -f "MODDIR_C/bin/alist" ];then
chmod 755 $MODDIR_C/bin/alist

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已为 alist 授予可执行权限" >> "${MODDIR_C}/log.txt"

fi

# 循环检查 sys.boot_completed 参数是否为 1 （即已完成开机启动）不为 1 则等待 5s
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  /system/bin/sleep 5
done

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已处于开机完成状态" >> "${MODDIR_C}/log.txt"

# 在后台（&表示后台运行）启动 alist_update.sh 服务
sh "$MODDIR/alist_update.sh" 2>> "${MODDIR_C}/log.txt" &

if [ ! -d "/data/adb/crond" ]; then
    mkdir "/data/adb/crond"
fi

chmod 755 "$MODDIR/alist_server.sh"
chmod 755 "$MODDIR/alist_update.sh"

echo "* * * * * $MODDIR/alist_server.sh" > "/data/adb/crond/root"
echo "0 4 * * * $MODDIR/alist_update.sh" >> "/data/adb/crond/root"
if [ -n "$(pgrep crond)" ]; then
    pkill crond
fi
crond -c "/data/adb/crond" -L "/data/adb/crond/log.txt"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已启动定时更新服务（每 24h 检查一次）" >> "${MODDIR_C}/log.txt"

# 检查一次 alist 进程是否存在。若进程不存在，启动进程。

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已开启进程守护（每 1min 检测一次进程）" >> "${MODDIR_C}/log.txt"

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
fi
