#!/usr/bin/env bash
###############################################################################
# config.example.sh
# 功能：cert-manager.sh 配置示例文件
# 说明：复制此文件内容到 cert-manager.sh 的相应位置，并修改为您的实际配置
###############################################################################

###################### 域名映射表示例 #######################################
# 行格式：域名  webroot路径  目标证书目录
# 说明：
# - 域名：需要申请证书的域名
# - webroot路径：该域名对应的网站根目录（用于 HTTP-01 验证）
# - 目标证书目录：证书文件的目标存储目录
###############################################################################

# 示例1：单个网站
read -r -d '' DOMAIN_MAP <<'EOF'
example.com          /var/www/html              /etc/nginx/ssl
EOF

# 示例2：多个域名，同一个网站
read -r -d '' DOMAIN_MAP <<'EOF'
example.com          /var/www/html              /etc/nginx/ssl
www.example.com      /var/www/html              /etc/nginx/ssl
EOF

# 示例3：多个网站，使用 Docker
read -r -d '' DOMAIN_MAP <<'EOF'
api.example.com      /home/projects/api         /home/docker/nginx/cert/api
web.example.com      /home/projects/web         /home/docker/nginx/cert/web
admin.example.com    /home/projects/admin       /home/docker/nginx/cert/admin
EOF

# 示例4：复杂的多域名配置
read -r -d '' DOMAIN_MAP <<'EOF'
# 主站点
example.com          /var/www/main              /etc/nginx/ssl/main
www.example.com      /var/www/main              /etc/nginx/ssl/main

# API 服务
api.example.com      /var/www/api               /etc/nginx/ssl/api
api-v2.example.com   /var/www/api-v2            /etc/nginx/ssl/api

# 管理后台
admin.example.com    /var/www/admin             /etc/nginx/ssl/admin

# 移动端
m.example.com        /var/www/mobile            /etc/nginx/ssl/mobile

# CDN 子域名
cdn.example.com      /var/www/cdn               /etc/nginx/ssl/cdn
static.example.com   /var/www/static            /etc/nginx/ssl/static
EOF

###############################################################################
# 全局参数配置示例
###############################################################################

# 基本配置
EMAIL="admin@example.com"        # 替换为您的邮箱地址
THRESHOLD_DAYS=30                # 证书剩余天数阈值（建议 15-30 天）
NGINX_CTN="nginx"                # Docker Nginx 容器名（如果使用 Docker）

# 高级配置
LOG=/var/log/cert-manager.log    # 日志文件路径
LOCK=/var/run/cert-manager.lock  # 锁文件路径
DRY_RUN=false                    # 是否启用测试模式

# 备份配置（可选）
BACKUP_ENABLED=true              # 是否启用备份
BACKUP_DIR="/backup/ssl-certs"   # 备份目录
BACKUP_RETENTION_DAYS=30         # 备份保留天数

# 通知配置（可选）
NOTIFICATION_ENABLED=false       # 是否启用通知
NOTIFICATION_EMAIL="alerts@example.com"  # 通知邮箱
WEBHOOK_URL=""                   # 企业微信/钉钉 Webhook URL

###############################################################################
# Nginx 配置示例
###############################################################################

# 如果您使用的是系统安装的 Nginx，请使用以下配置：
NGINX_RELOAD_CMD="systemctl reload nginx"

# 如果您使用的是 Docker 部署的 Nginx，请使用以下配置：
NGINX_RELOAD_CMD="docker exec nginx nginx -s reload"

# 如果您使用的是 Docker Compose，请使用以下配置：
NGINX_RELOAD_CMD="docker-compose exec nginx nginx -s reload"

###############################################################################
# webroot 路径说明
###############################################################################

# webroot 路径必须是 Nginx 配置中对应域名的根目录
# 例如，如果您的 Nginx 配置如下：
# 
# server {
#     listen 80;
#     server_name example.com;
#     root /var/www/html;
#     
#     location /.well-known/acme-challenge/ {
#         root /var/www/html;
#     }
# }
# 
# 那么 webroot 路径应该设置为：/var/www/html

###############################################################################
# 证书目录说明
###############################################################################

# 目标证书目录是证书文件的最终存储位置
# 脚本会将 Let's Encrypt 生成的证书复制到这个目录
# 
# 证书文件命名规则：
# - {域名}.pem  (完整证书链，对应 Let's Encrypt 的 fullchain.pem)
# - {域名}.key  (私钥文件，对应 Let's Encrypt 的 privkey.pem)
# 
# 例如：
# - example.com.pem
# - example.com.key

###############################################################################
# 使用说明
###############################################################################

# 1. 复制此文件为您的配置文件：
#    cp config.example.sh config.local.sh
# 
# 2. 编辑配置文件，修改为您的实际配置：
#    nano config.local.sh
# 
# 3. 将配置内容复制到 cert-manager.sh 的相应位置
# 
# 4. 首次运行前，请确保：
#    - webroot 目录存在且可写
#    - 证书目标目录存在且可写
#    - 域名已正确解析到服务器
#    - Nginx 配置正确
# 
# 5. 手动申请第一次证书：
#    certbot certonly --webroot -w /path/to/webroot -d your-domain.com \
#            --email your-email@example.com --agree-tos
# 
# 6. 测试运行脚本：
#    /usr/local/bin/cert-manager.sh 