# 项目信息

## 📦 部署机器人项目

**项目名称**: 钉钉自动部署机器人  
**GitHub 仓库**: git@github.com:maxsimbash/grading-system-platform.git  
**用途**: 通过钉钉机器人自动化部署 grading-system-platform 项目

---

## 🎯 要部署的目标项目

**项目名称**: Grading System Platform (评分系统平台)  
**仓库地址**: git@github.com:maxsimbash/grading-system-platform.git  

---

## 🚀 快速部署

### 1. 在服务器上部署机器人

```bash
# SSH 登录到你的服务器
ssh user@your-server

# 克隆机器人项目
cd /opt
git clone git@github.com:maxsimbash/grading-system-platform.git dingtalk-deploy-bot
cd dingtalk-deploy-bot

# 运行安装脚本
bash scripts/install.sh
```

### 2. 配置环境变量

```bash
vim .env
```

**关键配置:**

```env
# 服务端口
PORT=3000

# 钉钉机器人配置
DINGTALK_SECRET=SECxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DINGTALK_WEBHOOK=https://oapi.dingtalk.com/robot/send?access_token=xxxxx

# 项目配置 - grading-system-platform 的部署路径
PROJECT_PATH=/var/www/grading-system-platform
GIT_BRANCH=main

# Nginx 配置
NGINX_PATH=nginx
```

### 3. 准备目标项目目录

如果 grading-system-platform 还没有部署到服务器:

```bash
# 创建项目目录
sudo mkdir -p /var/www/grading-system-platform
sudo chown -R $(whoami):$(whoami) /var/www/grading-system-platform

# 克隆目标项目
cd /var/www
git clone git@github.com:maxsimbash/grading-system-platform.git

# 进入项目目录
cd grading-system-platform

# 初始化项目
pnpm install
pnpm build

# 配置 Nginx 指向构建目录
# 例如: root /var/www/grading-system-platform/dist;
```

### 4. 配置权限

```bash
# 1. 确保项目目录可写
sudo chown -R $(whoami):$(whoami) /var/www/grading-system-platform

# 2. 配置 Nginx reload 权限
sudo visudo
# 添加:
$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload

# 3. 配置 SSH 密钥 (如果还没有)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
cat ~/.ssh/id_rsa.pub
# 将公钥添加到 GitHub: Settings → SSH and GPG keys → New SSH key
```

### 5. 启动部署机器人

```bash
cd /opt/dingtalk-deploy-bot
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs deploy-bot
```

### 6. 配置钉钉机器人

1. 在钉钉群中添加自定义机器人
2. 安全设置选择"加签",复制密钥到 `.env` 的 `DINGTALK_SECRET`
3. 复制 Webhook 地址到 `.env` 的 `DINGTALK_WEBHOOK`
4. 重启机器人: `pm2 restart deploy-bot`

### 7. 测试部署

在钉钉群中 @机器人:

```
@部署助手 更新 grading-system
```

---

## 📋 典型的 Nginx 配置

为 grading-system-platform 配置 Nginx:

```nginx
# /etc/nginx/sites-available/grading-system
server {
    listen 80;
    server_name grading.your-domain.com;

    # 静态文件目录 (前端构建产物)
    root /var/www/grading-system-platform/dist;
    index index.html;

    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理 (如果有后端服务)
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

启用站点:

```bash
sudo ln -s /etc/nginx/sites-available/grading-system /etc/nginx/sites-enabled/
sudo nginx -t
sudo nginx -s reload
```

---

## 🔄 部署流程说明

当你在钉钉群 @机器人时,会自动执行:

```bash
# 1. 进入项目目录
cd /var/www/grading-system-platform

# 2. 拉取最新代码
git pull origin main

# 3. 安装依赖 (如果有新依赖)
pnpm install --prod=false

# 4. 重新构建
pnpm build
# 这会生成新的 dist/ 目录

# 5. 平滑重载 Nginx
nginx -s reload
# 新的静态文件立即生效
```

---

## 📊 目录结构

```
服务器目录结构:

/opt/dingtalk-deploy-bot/        # 部署机器人
├── src/                          # 机器人代码
├── scripts/                      # 辅助脚本
├── .env                          # 配置文件
└── ...

/var/www/grading-system-platform/ # 要部署的项目
├── src/                          # 源代码
├── dist/                         # 构建产物 (Nginx 指向这里)
├── package.json
├── pnpm-lock.yaml
└── ...
```

---

## ⚠️ 注意事项

### 1. SSH 密钥配置

确保服务器可以访问 GitHub:

```bash
# 测试 SSH 连接
ssh -T git@github.com

# 应该看到:
# Hi maxsimbash! You've successfully authenticated...
```

### 2. 构建输出目录

确认 `grading-system-platform` 的构建配置:

- 检查 `package.json` 中的 `build` 脚本
- 确认构建输出目录 (通常是 `dist/` 或 `build/`)
- Nginx 配置要指向正确的构建目录

### 3. 环境变量

如果项目需要环境变量:

```bash
# 在项目目录创建 .env
cd /var/www/grading-system-platform
vim .env

# 添加必要的环境变量
# API_URL=https://api.example.com
# ...
```

### 4. 并发部署

避免多人同时触发部署:
- 可以约定部署时间
- 或在钉钉群说明"正在部署中"
- 后续版本会添加队列管理

---

## 🧪 测试清单

部署完成后,检查:

- [ ] 服务器可以访问 GitHub (SSH 密钥配置)
- [ ] 项目目录有读写权限
- [ ] pnpm 已安装并可用
- [ ] Nginx 配置正确并已重载
- [ ] 机器人服务正常运行 (`pm2 status`)
- [ ] 钉钉机器人配置正确
- [ ] 在钉钉群测试部署成功

---

## 📞 故障排查

### 问题 1: Git pull 失败

```bash
# 检查 SSH 连接
ssh -T git@github.com

# 检查 Git 远程仓库
cd /var/www/grading-system-platform
git remote -v

# 手动测试 pull
git pull origin main
```

### 问题 2: pnpm build 失败

```bash
# 检查 Node.js 版本
node -v

# 清理重新安装
cd /var/www/grading-system-platform
rm -rf node_modules
rm -rf pnpm-lock.yaml
pnpm install
pnpm build
```

### 问题 3: Nginx reload 权限不足

```bash
# 检查 sudo 配置
sudo visudo

# 或在 .env 中使用 sudo
NGINX_PATH=sudo nginx
```

### 问题 4: 查看详细日志

```bash
# 机器人日志
pm2 logs deploy-bot

# 部署日志
tail -f /opt/dingtalk-deploy-bot/logs/deploy-$(date +%Y-%m-%d).log

# 错误日志
tail -f /opt/dingtalk-deploy-bot/logs/error-$(date +%Y-%m-%d).log
```

---

## 🎉 完成

配置完成后,你就可以在钉钉群中通过 @机器人 来自动部署 `grading-system-platform` 项目了!

**工作流程:**
1. 开发完成后提交代码到 GitHub
2. 在钉钉群 @部署助手
3. 机器人自动拉取最新代码并构建
4. 新版本自动上线

---

**项目**: Grading System Platform  
**仓库**: git@github.com:maxsimbash/grading-system-platform.git  
**最后更新**: 2024-12-30

