# 快速开始指南 ⚡

> 5 分钟快速部署钉钉自动部署机器人

## 📦 准备工作

确保你的服务器已安装:
- ✅ Node.js >= 16.x
- ✅ Git
- ✅ pnpm
- ✅ Nginx

---

## 🚀 一键安装

```bash
# 1. 克隆项目
git clone git@github.com:maxsimbash/grading-system-platform.git /opt/dingtalk-deploy-bot
cd /opt/dingtalk-deploy-bot

# 2. 运行安装脚本
bash scripts/install.sh
```

---

## ⚙️ 配置

### 1. 创建钉钉机器人

1. 打开钉钉群 → 群设置 → 智能群助手 → 添加机器人
2. 选择"自定义机器人"
3. 安全设置选择"加签",**复制密钥**
4. **复制 Webhook 地址**

### 2. 配置环境变量

```bash
vim .env
```

修改以下配置:

```env
# 钉钉机器人配置 (必填)
DINGTALK_SECRET=SECxxx... (刚才复制的密钥)
DINGTALK_WEBHOOK=https://oapi.dingtalk.com/robot/send?access_token=xxx

# 项目配置 (必填)
PROJECT_PATH=/var/www/your-project  (你要部署的项目路径)
GIT_BRANCH=main
```

### 3. 配置权限

```bash
# 项目目录权限
sudo chown -R $(whoami) /var/www/your-project

# Nginx reload 权限
sudo visudo
# 添加: your-user ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload
```

---

## 🎯 启动服务

```bash
# 生产环境启动
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs deploy-bot
```

---

## 🌐 配置公网访问

### 方式 1: 使用公网 IP

钉钉 Webhook 设置为:
```
http://your-server-ip:3000/webhook/dingtalk
```

### 方式 2: 使用域名 (推荐)

```bash
# 配置 Nginx 反向代理
bash scripts/setup-nginx.sh
```

然后在钉钉中配置:
```
http://deploy-bot.your-domain.com/webhook/dingtalk
```

---

## ✅ 测试

### 1. 健康检查

```bash
curl http://localhost:3000/health
```

### 2. 手动触发部署

```bash
curl -X POST http://localhost:3000/deploy
```

### 3. 钉钉群测试

在钉钉群中 @机器人,发送任意消息:
```
@部署助手 deploy
```

应该会收到部署进度和结果通知! 🎉

---

## 📊 常用命令

```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs deploy-bot

# 重启服务
pm2 restart deploy-bot

# 停止服务
pm2 stop deploy-bot

# 运行测试
bash scripts/test.sh
```

---

## ❓ 遇到问题?

1. 运行测试脚本: `bash scripts/test.sh`
2. 查看日志: `pm2 logs deploy-bot`
3. 查看 [FAQ.md](FAQ.md)
4. 查看详细文档: [DEPLOY.md](DEPLOY.md)

---

## 🎉 完成!

现在你可以在钉钉群中 @机器人来自动部署你的项目了!

**工作流程:**
```
1. 在钉钉群 @部署助手
2. 机器人自动执行:
   - git pull origin main
   - pnpm install
   - pnpm build
   - nginx -s reload
3. 收到部署结果通知
```

---

## 📚 更多文档

- [README.md](README.md) - 项目说明
- [DEPLOY.md](DEPLOY.md) - 详细部署指南
- [ARCHITECTURE.md](ARCHITECTURE.md) - 架构设计
- [FAQ.md](FAQ.md) - 常见问题解答

