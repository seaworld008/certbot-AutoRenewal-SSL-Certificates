#!/bin/bash
###############################################################################
# install.sh
# 功能：一键安装 Certbot 自动续签 SSL 证书系统
# 版本：1.0.0
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log_info "检测到操作系统: $OS $VER"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
}

# 安装 Certbot
install_certbot() {
    log_info "开始安装 Certbot..."
    
    if command -v snap >/dev/null 2>&1; then
        log_info "使用 Snap 安装 Certbot (推荐方式)"
        snap install core && snap refresh core
        snap install --classic certbot
        ln -sf /snap/bin/certbot /usr/bin/certbot
    else
        log_info "使用传统包管理器安装 Certbot"
        if command -v yum >/dev/null 2>&1; then
            yum install -y epel-release
            yum install -y certbot
        elif command -v apt >/dev/null 2>&1; then
            apt update
            apt install -y certbot
        else
            log_error "不支持的包管理器，请手动安装 Certbot"
            exit 1
        fi
    fi
    
    # 验证安装
    if certbot --version >/dev/null 2>&1; then
        log_info "Certbot 安装成功: $(certbot --version)"
    else
        log_error "Certbot 安装失败"
        exit 1
    fi
}

# 安装证书管理脚本
install_cert_manager() {
    log_info "安装证书管理脚本..."
    
    # 复制脚本到系统目录
    cp cert-manager.sh /usr/local/bin/
    chmod +x /usr/local/bin/cert-manager.sh
    
    # 创建日志目录
    mkdir -p /var/log
    touch /var/log/cert-manager.log
    
    log_info "证书管理脚本安装完成"
}

# 创建 systemd 服务
create_systemd_service() {
    log_info "创建 systemd 服务..."
    
    # 创建服务文件
    cat > /etc/systemd/system/cert-manager.service <<EOF
[Unit]
Description=SSL Certificate Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cert-manager.sh
User=root
StandardOutput=journal
StandardError=journal
EOF

    # 创建定时器文件
    cat > /etc/systemd/system/cert-manager.timer <<EOF
[Unit]
Description=SSL Certificate Manager Timer
Requires=cert-manager.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # 重载 systemd 并启用定时器
    systemctl daemon-reload
    systemctl enable cert-manager.timer
    systemctl start cert-manager.timer
    
    log_info "systemd 服务创建完成"
}

# 显示安装完成信息
show_completion_info() {
    log_info "安装完成！"
    echo
    echo "接下来的步骤："
    echo "1. 编辑 /usr/local/bin/cert-manager.sh，修改域名映射表和配置参数"
    echo "2. 手动申请第一次证书："
    echo "   certbot certonly --webroot -w /path/to/webroot -d your-domain.com --email your-email@example.com --agree-tos"
    echo "3. 运行一次脚本测试："
    echo "   /usr/local/bin/cert-manager.sh"
    echo "4. 查看日志："
    echo "   tail -f /var/log/cert-manager.log"
    echo "5. 查看定时器状态："
    echo "   systemctl status cert-manager.timer"
    echo
    echo "详细文档请查看 README.md"
}

# 主函数
main() {
    log_info "开始安装 Certbot 自动续签 SSL 证书系统"
    
    check_root
    detect_os
    
    # 检查必要文件
    if [[ ! -f "cert-manager.sh" ]]; then
        log_error "找不到 cert-manager.sh 文件"
        exit 1
    fi
    
    install_certbot
    install_cert_manager
    create_systemd_service
    show_completion_info
}

# 运行主函数
main "$@" 