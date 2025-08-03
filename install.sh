#!/bin/bash
#
#   Dante Socks5 Server AutoInstall (修正版)
#   -- 支持系统: Debian/Ubuntu, CentOS
#   -- 修复了URL解析错误，确保一键执行

# 检查是否为root用户
if [ $(id -u) != "0" ]; then
    echo "错误: 必须使用root用户运行此脚本，请切换到root后重试"
    exit 1
fi

# 服务器地址配置
SCRIPT_SERVER="https://public.sockd.info"
SYSTEM_TYPE=""
INSTALL_SCRIPT=""

# 检测操作系统类型
detect_os() {
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        OS=$NAME
    elif [ -f "/etc/centos-release" ]; then
        OS="CentOS"
    elif [ -f "/etc/debian_version" ]; then
        OS="Debian"
    else
        OS=$(uname -s)
    fi

    # 确定系统类型
    if [[ $OS == *"Ubuntu"* || $OS == *"Debian"* ]]; then
        SYSTEM_TYPE="debian"
        INSTALL_SCRIPT="install_debian.sh"
    elif [[ $OS == *"CentOS"* ]]; then
        SYSTEM_TYPE="centos"
        INSTALL_SCRIPT="install_centos.sh"
    else
        echo "不支持的操作系统: $OS"
        exit 1
    fi
    
    echo "检测到操作系统: $OS"
    echo "使用对应安装脚本: $INSTALL_SCRIPT"
}

# 安装依赖工具
install_dependencies() {
    echo "正在安装必要依赖..."
    if [ "$SYSTEM_TYPE" = "debian" ]; then
        apt update -y >/dev/null 2>&1
        apt install -y wget curl >/dev/null 2>&1
    else
        yum install -y wget curl >/dev/null 2>&1
    fi
    
    # 检查wget是否安装成功
    if ! command -v wget &> /dev/null; then
        echo "错误: 无法安装wget，请手动安装后重试"
        exit 1
    fi
}

# 下载并执行安装脚本
download_and_install() {
    echo "正在下载安装脚本..."
    local script_url="${SCRIPT_SERVER}/${INSTALL_SCRIPT}"
    local local_script="/tmp/${INSTALL_SCRIPT}"
    
    # 下载脚本
    if ! wget --no-check-certificate -q -O "$local_script" "$script_url"; then
        echo "错误: 无法下载安装脚本 $script_url"
        exit 1
    fi
    
    # 赋予执行权限
    chmod +x "$local_script"
    
    # 执行安装脚本
    echo "开始安装Dante Socks5服务器..."
    "$local_script" "$@" | tee /tmp/danted_install.log
    
    # 检查安装结果
    if [ $? -eq 0 ]; then
        echo "Dante Socks5服务器安装完成！"
        echo "安装日志已保存至 /tmp/danted_install.log"
    else
        echo "安装失败，请查看日志: /tmp/danted_install.log"
        exit 1
    fi
}

# 主流程
main() {
    detect_os
    install_dependencies
    download_and_install "$@"
}

# 启动主流程
main "$@"

exit 0
