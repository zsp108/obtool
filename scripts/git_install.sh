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

git_version="2.42.0"



# 打印欢迎信息
log info "欢迎使用 Git 安装脚本！"
log info "此脚本将会安装 Git $git_version。"
log info "正在执行安装操作，请耐心等待..."

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

#判断是否安装过git，如果有再确认是否卸载原安装的git
if [ `command  -v git` ];then
    cur_gitversion=`git --version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}'`
    log info "当前git版本为$cur_gitversion"
    if [[ $cur_gitversion == $git_version  ]];then
        log info "已安装的版本和将要安装的版本相同,不进行安装"
        return
    else
        log info "已安装的版本和将要安装的版本不同"
        read -p "是否删除已安装的git$cur_gitversion？(y/n):" is_del_git

        if [[ $is_del_git == 'y' ]];then
            case $OS in
                'centos' | 'rhel')
                    yum remove git -y
                    ;;
                'debian' | 'ubuntu')
                    apt remove git -y
                    ;;
            esac
        fi
    fi

fi

# 判断是否为 CentOS/RedHat 系统
if [[ $OS == 'centos' || $OS == 'rhel' ]]; then 
    yum -y update && \
    yum -y install epel-release && \
    yum install -y wget make autoconf automake cmake perl-CPAN libcurl-devel libtool gcc gcc-c++ glibc-headzlib-devel telnet ctags lrzsz jq expat-devel openssl-devel gettext openssh-server passwd
# 判断是否为 Ubuntu/Debian 系统
elif [[ $OS == 'ubuntu' || $OS == 'debian' ]]; then
    apt-get update && \
    apt-get install -y wget make autoconf automake cmake perl libwww-perl libcurl4-openssl-dev libtool gcc g++ glibc-doc telnet ctags lrzsz jq expat libexpat1-dev openssl libssl-dev gettext openssh-server passwd
else
    log error "不支持的操作系统类型。"
    # exit 1
fi

# 下载 Git 安装包
log info "正在下载 Git 安装包..."
if [ -f /tmp/git-$git_version.tar.gz ]; then
    log info "已存在 Git 安装包，跳过下载。"
else
    cd /tmp/ && curl -O https://mirrors.edge.kernel.org/pub/software/scm/git/git-$git_version.tar.gz
fi

echo "Git 下载完成。"

# 解压 Git 安装包
log info "正在解压 Git 安装包..."
cd /tmp/ && tar -zxvf git-$git_version.tar.gz

# 安装 Git
log info "正在安装 Git..."
cd /tmp/git-$git_version/
./configure --prefix=/usr/local/git
make -j`nproc`
make install -j`nproc`
cp /tmp/git-$git_version/contrib/completion/git-completion.bash $HOME/.git-completion.bash

# 设置环境变量
log info "正在设置环境变量..."
cat << 'EOF' >> $HOME/.bashrc

# Set PATH to include Git
export PATH=$PATH:/usr/local/git/bin
# Load Git auto-completion
if [ -f ~/.git-completion.bash ]; then
        . ~/.git-completion.bash
fi
EOF
source $HOME/.bashrc

# 测试 Git
log info "正在测试 Git..."
git --version

# 打印 Git 版本信息
log info "Git 安装成功。"
log info "Git 版本信息: $(git --version)"
