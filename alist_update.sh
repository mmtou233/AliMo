#!/system/bin/sh

# 获取当前脚本所在目录
MODDIR="$(dirname "$(readlink -f "$0")")"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] 当前脚本所在目录：${MODDIR}" >> "${MODDIR}/log.txt"

# busybox的路径地址
BUSYBOX_PATH="/data/adb/magisk/busybox:/data/adb/ksu/bin/busybox:/data/adb/ap/bin/busybox"
BUSYBOX=""

# 获取最新版本号
# curl 向服务器传输数据，-L 跟随重定向，-s 不显示进度和错误信息
# grep 文本搜索工具，搜索包含字符串 "tag_name": 的一行
# sed 流编辑器，对输入流（或文件）进行文本转换。-E 使用正则表达式

# s/.*"([^"]+)".*/\1/ 正则表达式，匹配最后双引号内的内容

# s/.../.../ sed 的替换命令的基本结构。它告诉 sed 要查找一个模式（在第一个 ... 中）并用另一个字符串（在第二个 ... 中）替换它。

# "([^"]+)" 这是一个稍微复杂的正则表达式，用于匹配被双引号包围的字符串。让我们分解它：
# " 匹配双引号字符。
# (...) 这是一个捕获组，它允许我们引用后面匹配到的文本。
# [^"]+ 这是一个字符类，它匹配任何不是双引号的字符（[^"]）一次或多次（+）。
# " 再次匹配双引号字符。
# 因此，([^"]+) 捕获了双引号之间的所有内容。

# \1 这是一个反向引用，它引用了第一个捕获组，即 ([^"]+)）匹配到的文本。
get_latest_version() {
    url_version="$(curl -Ls "https://api.github.com/repos/alist-org/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
    
    if [ -z "${url_version}" ]; then
    
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 远程版本号获取失败，开始使用备用方案" >> "${MODDIR}/log.txt"
        
        url_version="$(curl -sL -o /dev/null -w '%{url_effective}' "https://gh.con.sh/https://github.com/alist-org/alist/releases/latest" | grep 'tag' | sed -E 's/.*tag\/(.*)/\1/')"
    fi
}

# 获取本地版本号
# 2>/dev/null：这是一个重定向操作，它将命令的标准错误（文件描述符2）重定向到 /dev/null ，这意味着任何错误消息都会被丢弃，你不会在终端看到它们。
# || echo 0：这是一个条件操作符。如果前面的命令（即`${MODDIR}/bin/alist -v`）执行失败，则执行 echo 0
get_version() {
    version="$("${MODDIR}/bin/alist" version  2>/dev/null | grep '^Version:' | sed -E 's/.*(v.+)/\1/')"
    if [ -z "${version}" ]; then
    version=0
    fi
}

# 检查网络连通性函数
# ping: 是用于测试网络连接性的命令。
# -q: 安静模式，不显示任何输出（除了错误消息）。
# -c 1: 只发送一个ping请求。
# -W 1: 设置等待每个响应的超时时间为1秒。
# www.baidu.com: 要ping的目标地址。
# >/dev/null: 将ping命令的标准输出重定向到/dev/null，即丢弃输出，不显示在屏幕上。
check_connectivity() {
    if ! ping -q -c 1 -W 1 www.baidu.com >/dev/null; then
        sleep 5
        return 1
    fi
    return 0
}

# 找到可用的busybox路径
# echo "$BUSYBOX_PATH" | tr ":" "\n"`：这部分命令使用 echo 打印 $BUSYBOX_PATH 的值，并通过 tr 命令将冒号（`:`）替换为换行符（`\n`）。这样，原本由冒号分隔的路径就被转换成了多行输出。
# for path in ...; do ... done：这是一个循环结构，它会遍历上面提到的多行输出（即路径列表），并将每一行赋值给变量 path。
# -f: 是普通文件       -d: 是目录
# -e: 文件存在         -s: 文件大小非零
# -r: 文件可读 -w: 文件可写 -x: 文件可执行
# -nt: 文件1比文件2新 -ot: 文件1比文件2旧
find_busybox() {
    for path in $(echo "$BUSYBOX_PATH" | tr ":" "\n"); do
        if [ -f "$path" ]; then
            BUSYBOX="$path"
            
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 成功获取busybox路径：${BUSYBOX}" >> "${MODDIR}/log.txt"
            
            break
        fi
    done
}

# 删除大于1MB的log.txt文件
# wc -c: 获取指定文件大小（以字节为单位）
# -gt: 大于      -lt: 小于
# -ge: 大于等于 -le: 小于等于
# -eq: 等于      -ne: 不等于
delete_log() {
    log_size=$(wc -c < "${MODDIR}/log.txt")
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 当前日志文件大小为：$(echo "scale=2; $log_size / 1024" | bc)KB" >> "${MODDIR}/log.txt"
    
    if [ "$log_size" -gt 1048576 ]; then
        rm "${MODDIR}/log.txt"
        
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 日志文件（大于1MB）重置完成" >> "${MODDIR}/log.txt"
        
    fi
}

# 下载并解压更新包
download_and_extract() {
    alist_file="alist-android-arm64.tar.gz"
    mkdir -p "${MODDIR}/tmp"
    mkdir -m 755 -p "${MODDIR}/bin"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已创建临时文件夹tmp和二进制文件夹bin" >> "${MODDIR}/log.txt"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 开始下载最新版" >> "${MODDIR}/log.txt"
    
    "${BUSYBOX}" wget -O "${MODDIR}/tmp/${alist_file}" "https://gh.con.sh/https://github.com/alist-org/alist/releases/download/${url_version}/${alist_file}" &>>"${MODDIR}/log.txt"
    
    chmod 755 "${MODDIR}/tmp/${alist_file}"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 下载完成，已授予 alist 压缩包 755 权限" >> "${MODDIR}/log.txt"
    
    "${BUSYBOX}" tar -xzf "${MODDIR}/tmp/${alist_file}" -C "${MODDIR}/tmp" &>/dev/null
    mv -f "${MODDIR}/tmp/alist" "${MODDIR}/bin/alist"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已将 alist 解压并移动到指定目录" >> "${MODDIR}/log.txt"
    
    chmod 755 "${MODDIR}/bin/alist"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已授予 alist 可执行权限" >> "${MODDIR}/log.txt"
    
    rm -r "${MODDIR}/tmp"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 临时文件已清除" >> "${MODDIR}/log.txt"
    
}

# 比较版本号函数
# $2 是更新的版本则为真，否则为假
version_ge() {
    test "$(echo -e "$1\n$2" | sort -V | tail -n 1)" = "$2"
}

# 更新列表并重启进程
update_and_restart() {
    get_version
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 更新后本地版本：${version}" >> "${MODDIR}/log.txt"
    
    sed -i "s/^version=.*/version=${version}/g" "${MODDIR}/module.prop"
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已更新 module.prop 文件" >> "${MODDIR}/log.txt"
    
    if [ -n "$(pgrep 'alist')" ]; then
        pkill alist 
        
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已结束 alist 进程" >> "${MODDIR}/log.txt"
        
    fi

    $MODDIR/bin/alist server >/dev/null 2>&1 &
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 启动 alist 进程完毕" >> "${MODDIR}/log.txt"
}

# 更新失败
handle_failed_update() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 更新失败！" >> "${MODDIR}/log.txt"
}

# 更新检测
check_and_update_version() {
    # 获取最新版本号
    retry_times=0
    while true; do
        get_latest_version
        # -n: 检查字符串长度是否非零
        if [ -n "$url_version" ]; then
        
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 远程 alist 最新版：${url_version}" >> "${MODDIR}/log.txt"
    
            break
        fi

        ((retry_times++))
        if [ $((retry_times % 60)) -eq 0 ]; then
        
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] 获取URL版本号失败..." >> "${MODDIR}/log.txt"
            
        fi

        sleep 30m
    done
 
    if [ ! -x "${MODDIR}/bin/alist" ]; then
    
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 不存在本地 alist ，从远程链接下载。。。" >> "${MODDIR}/log.txt"
        
        download_and_extract
        update_and_restart
        ${MODDIR}/bin/alist admin set 123456789 &>/dev/null
        
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 初始密码已重置为: 123456789" >> "${MODDIR}/log.txt"
        
        return
    fi
    
    get_version
    if version_ge "${url_version}" "${version}"; then
    
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 已是最新版本：${version}" >> "${MODDIR}/log.txt"
        
        sed -i "s/^version=.*/version=${version}/g" "${MODDIR}/module.prop"
    else
    
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] ${version}，更新中..." >> "${MODDIR}/log.txt"
        
        download_and_extract
        
        max_attempts=3  # 最大重试次数
        attempt=0  # 当前重试次数

        while [ $attempt -le $max_attempts ]; do
            sleep 10s
            get_version
            if [[ "${url_version}" == "${version}" ]]; then
                update_and_restart
                break
            else
                ((attempt++))
                if [ $attempt -gt $max_attempts ]; then
                    handle_failed_update
                    break
                fi
                
                echo "[$(date "+%Y-%m-%d %H:%M:%S")] 更新失败，正在重试（当前重试次数：${attempt} 次）。。。" >> "${MODDIR}/log.txt"
                
                download_and_extract
            fi
        done
    fi
}

# 查找并设置busybox路径
find_busybox

while true; do
    delete_log
    if ! check_connectivity; then
        echo "[$(date "+%Y-%m-%d %H:%M:%S")] 网络异常，5s 后重试" >> "${MODDIR}/log.txt"
        
        sleep 5s
        continue
    fi
    check_and_update_version
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 当前版本为：${version} 定时更新服务正常运行。。。" >> "${MODDIR}/log.txt"
    
    sleep 24h
    
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] 开始检查更新。。。" >> "${MODDIR}/log.txt"
done