#!/bin/bash

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd -P)"

logfile=$SCRIPT_ROOT/init.log
# 日志函数，记录操作系统，并且将输出打印到屏幕
function log {
    local msg
    local logtype
    logtype=$1
    msg=$2
    datetime=`date +'%F %H:%M:%S'`
    logformat="${datetime} ${FUNCNAME[@]/log/} [line:`caller 0 | awk '{print$1}'`] ${logtype}:${msg}"
    {
    case $logtype in
        debug)
            echo "${logformat}" &>> $logfile;;
        info)
            echo -e "\033[32m $datetime [info] ${msg} \t \033[0m"
            echo "${logformat}" &>> $logfile;;
        warn)
            echo -e "\033[33m $datetime [WARN] ${msg} \t \033[0m"
            echo "${logformat}" &>> $logfile;;
        error)
            echo -e "\033[31m $datetime [ERROR] ${msg} \033[0m"
            echo "${logformat}" &>> $logfile
            exit 15;;
    esac
    }
}

# 获取 CPU 架构
ARCH=$(uname -m)

# 获取系统版本信息（支持 CentOS/RedHat 或 Ubuntu/Debian）
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    log error "无法确定操作系统类型。"
    exit 1
fi

# 打印系统信息
log info "检测到系统架构: $ARCH"
log info "检测到操作系统: $OS $VERSION"

# 检查是否安装 gitlint
if [ -x "$(command -v gitlint)" ]; then
    log info "gitlint 已安装，跳过安装步骤。"
    exit 0
fi

# 安装 gitlint
function install_gitlint {
    log info "正在安装 gitlint..."
    log info "正在下载gitlint 二进制包..."
    if [ -f /tmp/gitlint.tar.gz ]; then
        log info "已存在 gitlint 二进制包，跳过下载步骤。"
    else
        wget https://github.com/llorllale/go-gitlint/archive/refs/tags/1.1.0.tar.gz -O /tmp/gitlint.tar.gz
        if [ $? -ne 0 ]; then
            log error "下载 gitlint 二进制包失败。"
        exit 1
        fi
    fi
    
    log info "下载完成，正在安装..."
    cd /tmp/
    tar -zxvf gitlint.tar.gz
    cd go-gitlint-1.1.0/
    make build
    if [ $? -ne 0 ]; then
        log error "安装 gitlint 失败。"
        exit 1
    fi

    cp gitlint /usr/local/bin/gitlint

    # 验证安装
    if [ -x "$(command -v gitlint)" ]; then
        log info "gitlint 安装成功。"
    else
        log error "gitlint 安装失败。"
        exit 1
    fi
}

# 卸载 gitlint
function uninstall_gitlint {
    log info "正在卸载 gitlint..."
    if [ -x "$(command -v gitlint)" ]; then
        rm -f /usr/local/bin/gitlint
    else
        log info "gitlint 未安装，跳过卸载步骤。"
    fi
    log info "gitlint 卸载完成。"
}

# 执行安装/卸载操作
if [ "$1" == "install" ]; then
    install_gitlint
elif [ "$1" == "uninstall" ]; then
    uninstall_gitlint
else
    log error "未知命令。"
    exit 1
fi


