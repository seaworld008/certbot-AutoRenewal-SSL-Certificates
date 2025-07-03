# Certbot 自动续签 SSL 证书

🔒 一个基于 Certbot 的 SSL 证书自动续签解决方案，支持多域名管理、智能检测到期时间、自动续签并热重载 Nginx。

## ✨ 功能特性

- 🚀 **自动续签**：智能检测证书到期时间，自动续签即将过期的证书
- 🌐 **多域名支持**：通过配置表轻松管理多个域名的证书
- 🔄 **热重载**：证书更新后自动重载 Nginx，无需服务中断
- 📊 **详细日志**：完整的操作日志记录，便于监控和调试
- 🔒 **防并发**：内置锁机制，防止重复执行
- 📁 **灵活部署**：支持将证书复制到指定目录，适配各种部署场景

## 🛠️ 系统要求

- **操作系统**：CentOS 7/8、AlmaLinux、RHEL 7/8 或其他 Linux 发行版
- **Web服务器**：Nginx（支持 Docker 部署）
- **权限**：root 或 sudo 权限
- **网络**：服务器需要能够访问互联网

## 📦 安装步骤

### 方式一：Snap 安装（推荐）

```bash
# 安装 snapd
sudo yum install -y epel-release
sudo yum install -y snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

# 安装 certbot
sudo snap install core && sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# 验证安装
certbot --version
```

### 方式二：传统 RPM 安装

```bash
# 安装 EPEL 源和 certbot
sudo yum install -y epel-release
sudo yum install -y certbot

# 验证安装
certbot --version
```

## ⚙️ 配置说明

### 1. 下载脚本

```bash
# 克隆项目
git clone https://github.com/your-username/certbot-AutoRenewal-SSL-Certificates.git
cd certbot-AutoRenewal-SSL-Certificates

# 复制脚本到系统目录
sudo cp cert-manager.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/cert-manager.sh
```

### 2. 修改配置

编辑 `/usr/local/bin/cert-manager.sh` 文件，修改以下配置：

#### 域名映射表
```bash
# 行格式：域名  webroot路径  目标证书目录
read -r -d '' DOMAIN_MAP <<'EOF'
example.com          /home/projects/official      /home/docker/nginx/cert/official
www.example.com      /home/projects/official      /home/docker/nginx/cert/official
merp.example.com     /home/projects/erp-mobile-ui /home/docker/nginx/cert/erp
erp.example.com      /home/projects/erp-ui        /home/docker/nginx/cert/erp
tablet.example.com   /home/projects/tablet-ui     /home/docker/nginx/cert/erp
EOF
```

#### 全局参数
```bash
EMAIL="admin@example.com"   # 替换为您的邮箱
THRESHOLD_DAYS=25            # 证书剩余天数阈值
NGINX_CTN="nginx"            # Docker Nginx 容器名
```

### 3. 首次证书申请

在运行自动续签脚本之前，需要手动申请一次证书：

```bash
# 示例：为 example.com 申请证书
certbot certonly --webroot -w /home/projects/official -d example.com \
       --email admin@example.com --agree-tos --force-renewal
```

## 🚀 使用方法

### 手动执行

```bash
# 手动运行一次脚本
sudo /usr/local/bin/cert-manager.sh
```

### 定时任务

添加到 crontab 实现自动化：

```bash
# 编辑 crontab
sudo crontab -e

# 添加以下行（每天凌晨 2:30 执行）
30 2 * * * /usr/local/bin/cert-manager.sh >/dev/null 2>&1
```

### Systemd Timer（推荐）

创建 systemd 服务和定时器：

```bash
# 创建服务文件
sudo tee /etc/systemd/system/cert-manager.service <<EOF
[Unit]
Description=SSL Certificate Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cert-manager.sh
User=root
EOF

# 创建定时器文件
sudo tee /etc/systemd/system/cert-manager.timer <<EOF
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

# 启用并启动定时器
sudo systemctl daemon-reload
sudo systemctl enable cert-manager.timer
sudo systemctl start cert-manager.timer

# 查看定时器状态
sudo systemctl status cert-manager.timer
```

## 📋 工作流程

1. **防并发检查**：检查是否有其他实例正在运行
2. **证书巡检**：检查所有配置域名的证书到期时间
3. **智能续签**：仅对剩余天数小于阈值的证书进行续签
4. **文件同步**：将新证书复制到指定目录
5. **服务重载**：验证 Nginx 配置并热重载服务

## 📊 日志查看

脚本运行日志保存在 `/var/log/cert-manager.log`：

```bash
# 查看最新日志
sudo tail -f /var/log/cert-manager.log

# 查看特定日期的日志
sudo grep "2024-01-01" /var/log/cert-manager.log
```

## 🔍 故障排除

### 常见问题

#### 1. 证书申请失败
```bash
# 检查域名解析
nslookup your-domain.com

# 检查 webroot 路径是否可访问
curl -I http://your-domain.com/.well-known/acme-challenge/test

# 手动测试申请
certbot certonly --dry-run --webroot -w /path/to/webroot -d your-domain.com
```

#### 2. Nginx 重载失败
```bash
# 检查 Nginx 配置
sudo nginx -t

# 检查 Docker 容器状态
docker ps | grep nginx

# 手动重载测试
docker exec nginx nginx -s reload
```

#### 3. 权限问题
```bash
# 检查脚本权限
ls -la /usr/local/bin/cert-manager.sh

# 检查证书目录权限
ls -la /etc/letsencrypt/live/
```

### 调试模式

在脚本开头添加调试选项：

```bash
#!/usr/bin/env bash
set -x  # 启用调试模式
```

## 🔧 高级配置

### 自定义通知

可以在脚本中添加邮件或企业微信通知：

```bash
# 发送邮件通知（需要配置 mailx）
echo "证书续签完成" | mail -s "SSL证书续签通知" admin@example.com

# 企业微信通知示例
curl -X POST "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY" \
     -H 'Content-Type: application/json' \
     -d '{"msgtype": "text","text": {"content": "SSL证书续签完成"}}'
```

### 证书备份

添加证书备份功能：

```bash
# 在脚本中添加备份逻辑
BACKUP_DIR="/backup/ssl-certs"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/certs-$(date +%Y%m%d).tar.gz" /etc/letsencrypt/
```

## 📄 许可证

本项目采用 MIT 许可证。详情请查看 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📞 支持

如果您在使用过程中遇到问题，可以：

- 查看 [Issues](https://github.com/your-username/certbot-AutoRenewal-SSL-Certificates/issues)
- 提交新的 Issue
- 发送邮件至：your-email@example.com

## 🎯 待办事项

- [ ] 支持通配符证书
- [ ] 添加多种通知方式（邮件、微信、钉钉）
- [ ] 支持多种 Web 服务器（Apache、Caddy）
- [ ] 添加证书监控仪表板
- [ ] 支持自定义 DNS 验证

---

⭐ 如果这个项目对您有帮助，请给它一个 Star！ 