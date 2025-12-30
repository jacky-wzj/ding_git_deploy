# 钉钉机器人自动部署系统

## 架构设计

### 整体架构
```
钉钉群 (@机器人) 
    ↓
钉钉服务器 (webhook推送)
    ↓
你的服务器 (Node.js服务)
    ↓
执行部署命令 (git pull → pnpm install → pnpm build → nginx reload)
    ↓
返回执行结果到钉钉群
```

### 技术栈
- **后端服务**: Node.js + Express
- **钉钉机器人**: 企业自建机器人 (Webhook 方式)
- **安全验证**: 钉钉签名校验
- **命令执行**: child_process
- **进程管理**: PM2
- **日志**: Winston

---

## 功能特性

✅ 安全的钉钉签名验证  
✅ 异步命令执行，避免超时  
✅ 实时反馈执行进度  
✅ 详细的日志记录  
✅ 错误处理和回滚提示  
✅ PM2 进程守护  

---

## 快速开始

### 1. 钉钉机器人配置

1. 进入钉钉群 → **群设置** → **智能群助手** → **添加机器人** → **自定义机器人**
2. 设置机器人名称，例如：**部署助手**
3. **安全设置**：选择 **加签** 方式（复制密钥，后续需要配置到环境变量）
4. 复制 **Webhook 地址**（后续需要配置）
5. 勾选 **@才能触发**（可选，建议勾选）

### 2. 服务器部署

#### 2.1 克隆代码
```bash
cd /opt
git clone git@github.com:maxsimbash/grading-system-platform.git dingtalk-deploy-bot
cd dingtalk-deploy-bot
```

#### 2.2 安装依赖
```bash
npm install
# 或
pnpm install
```

#### 2.3 配置环境变量
```bash
cp .env.example .env
vim .env
```

配置内容：
```env
# 服务端口
PORT=3000

# 钉钉机器人配置
DINGTALK_SECRET=SECxxxxxxxxxxxxxxxxxxxxxxxxxxxx    # 钉钉机器人的加签密钥
DINGTALK_WEBHOOK=https://oapi.dingtalk.com/robot/send?access_token=xxxxx

# 项目路径（需要部署的项目路径）
PROJECT_PATH=/var/www/your-project

# Git 分支
GIT_BRANCH=main

# Nginx 配置（可选，如果nginx不在PATH中）
NGINX_PATH=nginx
```

#### 2.4 权限配置

确保运行服务的用户有以下权限：
```bash
# 1. 项目目录的读写权限
sudo chown -R $(whoami) /var/www/your-project

# 2. nginx reload 权限（方式1：sudo免密）
sudo visudo
# 添加：
your-user ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload
your-user ALL=(ALL) NOPASSWD: /usr/local/bin/nginx -s reload

# 或方式2：使用 setcap（推荐）
sudo setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx
```

#### 2.5 启动服务

**开发环境：**
```bash
npm run dev
```

**生产环境（使用 PM2）：**
```bash
# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start ecosystem.config.js

# 查看日志
pm2 logs deploy-bot

# 其他常用命令
pm2 status          # 查看状态
pm2 restart deploy-bot
pm2 stop deploy-bot
pm2 delete deploy-bot
```

#### 2.6 配置开机自启（可选）
```bash
pm2 startup
pm2 save
```

### 3. Nginx 反向代理配置（可选）

如果需要通过域名访问，配置 Nginx：

```nginx
server {
    listen 80;
    server_name deploy-bot.your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 4. 测试

在钉钉群里 @机器人，发送任意消息，机器人会自动执行部署流程。

---

## 使用说明

### 触发部署

在钉钉群中 @部署助手机器人，发送任意消息即可触发部署：
```
@部署助手 发布新版本
@部署助手 部署
@部署助手 deploy
```

### 执行流程

1. ✅ 收到部署请求
2. 🔄 正在拉取最新代码...
3. 🔄 正在安装依赖...
4. 🔄 正在构建项目...
5. 🔄 正在重载 Nginx...
6. ✅ 部署完成！

---

## 安全建议

1. ✅ **必须启用**钉钉加签验证
2. ✅ **限制**机器人只能由群主/管理员添加
3. ✅ **配置** sudo 免密时，只允许特定命令
4. ✅ **定期检查**日志文件
5. ✅ **使用** PM2 守护进程，自动重启
6. ✅ **备份**重要数据，防止意外

---

## 常见问题

### 1. 钉钉没有收到回调？
- 检查服务器端口是否开放（安全组/防火墙）
- 检查服务是否正常运行：`pm2 status`
- 查看服务日志：`pm2 logs deploy-bot`

### 2. 命令执行失败？
- 检查项目路径是否正确
- 检查用户权限（git、pnpm、nginx）
- 查看错误日志：`logs/deploy.log`

### 3. Nginx reload 权限不足？
```bash
# 方案1：配置 sudo 免密
sudo visudo
# 添加：your-user ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload

# 方案2：修改代码中的 NGINX 命令为 sudo nginx
```

### 4. 如何回滚？
机器人不会自动回滚，需要手动操作：
```bash
cd /var/www/your-project
git reset --hard <commit-id>
pnpm install
pnpm build
nginx -s reload
```

---

## 项目结构

```
dingtalk-deploy-bot/
├── src/
│   ├── index.js           # 入口文件
│   ├── config.js          # 配置管理
│   ├── dingtalk.js        # 钉钉消息处理
│   ├── deploy.js          # 部署逻辑
│   └── utils/
│       └── logger.js      # 日志工具
├── logs/                  # 日志目录
├── .env.example           # 环境变量示例
├── .env                   # 环境变量（需创建）
├── .gitignore
├── package.json
├── ecosystem.config.js    # PM2 配置
└── README.md
```

---

## License

MIT

# ding_git_deploy
