#!/system/bin/sh

# 获取绝对路径目录
MODDIR="$(dirname "$(readlink -f "$0")")"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已获取绝对路径地址：${MODDIR}" >> "${MODDIR}/log.txt"

# 为 alist 二进制文件授予可执行权限
if [ -f "$MODDIR/bin/alist" ];then
chmod 755 $MODDIR/bin/alist

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已为 alist 授予可执行权限" >> "${MODDIR}/log.txt"

fi

# 循环检查 sys.boot_completed 参数是否为 1 （即已完成开机启动）不为 1 则等待 5s
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5
done

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已处于开机完成状态" >> "${MODDIR}/log.txt"

# 在后台（&表示后台运行）启动 alist_update.sh 服务
/system/bin/sh "$MODDIR/alist_update.sh" &

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已启动定时更新服务（每 24h 检查一次）" >> "${MODDIR}/log.txt"

# 无限循环，每 10s 检查一次 alist 进程是否存在。若进程不存在，启动进程。

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已开启进程守护（每 10s 检测一次进程）" >> "${MODDIR}/log.txt"

while true; do
    process="$(pgrep alist)"
    if [ -z "$process" ]; then
        if [ -f "$MODDIR/bin/alist" ]; then
        
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 检测到 alist 终止，正在重新启动。。。" >> "${MODDIR}/log.txt"
        
            $MODDIR/bin/alist server &>/dev/null &
        
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 重启进程完毕" >> "${MODDIR}/log.txt"
            
        else
        
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 等待 alist 完成下载。。。" >> "${MODDIR}/log.txt"
            
            sleep 300
        
        fi
    fi
    sleep 10
done
