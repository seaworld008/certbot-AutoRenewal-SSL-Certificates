# 更新日志

本文档记录了项目的所有重要变更。

## [1.0.0] - 2024-12-19

### 新增功能
- 🎉 首次发布 Certbot 自动续签 SSL 证书解决方案
- 🚀 支持多域名管理，通过配置表轻松管理多个域名的证书
- 🔄 智能检测证书到期时间，自动续签即将过期的证书
- 📊 完整的操作日志记录，便于监控和调试
- 🔒 内置锁机制，防止重复执行
- 📁 灵活的证书部署，支持将证书复制到指定目录
- 🔥 热重载 Nginx，证书更新后自动重载服务
- 🛠️ 一键安装脚本，支持 CentOS/AlmaLinux/RHEL 7/8
- ⚙️ systemd 定时器支持，提供可靠的定时任务
- 📖 详细的配置示例和文档

### 包含文件
- `cert-manager.sh` - 核心证书管理脚本
- `install.sh` - 一键安装脚本
- `config.example.sh` - 配置示例文件
- `nginx.example.conf` - Nginx 配置示例
- `README.md` - 详细的使用文档
- `LICENSE` - MIT 许可证
- `.gitignore` - Git 忽略文件配置

### 支持的功能
- ✅ HTTP-01 验证方式
- ✅ 多域名证书管理
- ✅ 智能证书到期检测
- ✅ 自动证书续签
- ✅ 证书文件同步
- ✅ Nginx 热重载
- ✅ Docker 环境支持
- ✅ 详细日志记录
- ✅ 防并发执行
- ✅ 系统服务集成

### 技术栈
- Bash Shell 脚本
- Certbot (Let's Encrypt)
- Nginx Web 服务器
- systemd 定时器
- OpenSSL

---

## 未来计划

### [1.1.0] - 计划中
- [ ] 支持通配符证书 (DNS-01 验证)
- [ ] 添加邮件通知功能
- [ ] 支持企业微信/钉钉通知
- [ ] 证书监控仪表板
- [ ] 支持 Apache Web 服务器

### [1.2.0] - 计划中
- [ ] 支持多种 DNS 提供商的 API
- [ ] 证书备份和恢复功能
- [ ] Web 管理界面
- [ ] 配置验证工具
- [ ] 性能优化

### [2.0.0] - 长期计划
- [ ] 分布式证书管理
- [ ] 云平台集成 (AWS, 阿里云等)
- [ ] Kubernetes 支持
- [ ] API 接口
- [ ] 插件系统

---

## 贡献指南

我们欢迎各种形式的贡献：

1. **Bug 报告**：发现问题请提交 Issue
2. **功能建议**：有好的想法请告诉我们
3. **代码贡献**：提交 Pull Request
4. **文档改进**：帮助完善文档
5. **使用反馈**：分享使用经验

## 联系方式

- GitHub Issues: [提交问题](https://github.com/your-username/certbot-AutoRenewal-SSL-Certificates/issues)
- 邮箱: your-email@example.com

---

*注意：版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。* 