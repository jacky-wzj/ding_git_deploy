# 部署指南

## 📋 前置要求

### 服务器环境
- ✅ Node.js >= 16.x
- ✅ npm 或 pnpm
- ✅ Git
- ✅ PM2 (推荐)
- ✅ Nginx

### 权限要求
- ✅ 项目目录的读写权限
- ✅ Git 仓库的访问权限
- ✅ Nginx reload 权限

---

## 🚀 部署步骤

### 第一步: 服务器准备

#### 1.1 安装 Node.js
```bash
# 使用 nvm 安装 (推荐)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18

# 或使用系统包管理器
# Ubuntu/Debian
sudo apt update
sudo apt install -y nodejs npm

# CentOS/RHEL
sudo yum install -y nodejs npm
```

#### 1.2 安装 pnpm
```bash
npm install -g pnpm
```

#### 1.3 安装 PM2
```bash
npm install -g pm2
```

#### 1.4 验证安装
```bash
node -v
npm -v
pnpm -v
pm2 -v
git --version
nginx -v
```

---

### 第二步: 克隆项目

```bash
# 选择一个目录部署机器人服务
cd /opt

# 克隆代码
git clone git@github.com:maxsimbash/grading-system-platform.git dingtalk-deploy-bot

# 进入项目目录
cd dingtalk-deploy-bot
```

---

### 第三步: 配置钉钉机器人

#### 3.1 创建钉钉机器人

1. 打开钉钉群聊
2. 点击右上角 `···` → `群设置`
3. 选择 `智能群助手` → `添加机器人`
4. 选择 `自定义` 机器人
5. 设置机器人信息:
   - 机器人名称: `部署助手` (或其他名称)
   - 消息推送地址: 稍后配置服务器后再设置
6. **重要**: 安全设置选择 `加签` 方式
   - 复制生成的 **密钥** (格式: SECxxxx...)
   - 保存密钥,稍后需要配置到 .env 文件
7. 勾选 `我已阅读并同意《自定义机器人服务及免责条款》`
8. 点击 `完成`
9. 复制机器人的 **Webhook 地址**

#### 3.2 钉钉机器人配置示例

```
机器人名称: 部署助手
Webhook: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxxx
密钥: SECxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 第四步: 配置项目

#### 4.1 安装依赖
```bash
cd /opt/dingtalk-deploy-bot
pnpm install
```

#### 4.2 创建环境变量文件
```bash
cp env.example .env
vim .env
```

#### 4.3 配置 .env 文件
```env
# 服务端口 (默认3000)
PORT=3000

# 钉钉机器人配置
DINGTALK_SECRET=SECxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DINGTALK_WEBHOOK=https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxxx

# 项目配置 (要部署的实际项目路径)
PROJECT_PATH=/var/www/your-project
GIT_BRANCH=main

# Nginx 配置
NGINX_PATH=nginx
```

**重要参数说明:**
- `DINGTALK_SECRET`: 钉钉机器人的加签密钥
- `DINGTALK_WEBHOOK`: 钉钉机器人的 Webhook 地址
- `PROJECT_PATH`: 要自动部署的项目路径 (不是机器人的路径!)
- `GIT_BRANCH`: Git 分支名
- `NGINX_PATH`: nginx 命令路径,如果需要 sudo 则设置为 `sudo nginx`

---

### 第五步: 配置权限

#### 5.1 项目目录权限
```bash
# 确保当前用户对项目目录有读写权限
sudo chown -R $(whoami):$(whoami) /var/www/your-project
```

#### 5.2 Git SSH 密钥配置 (如果使用私有仓库)
```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 将公钥添加到 Git 服务器 (GitHub/GitLab/Gitee)
cat ~/.ssh/id_rsa.pub
```

#### 5.3 Nginx reload 权限

**方式 1: 配置 sudo 免密 (推荐)**
```bash
sudo visudo

# 在文件末尾添加 (替换 your-username 为实际用户名):
your-username ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload
your-username ALL=(ALL) NOPASSWD: /usr/local/nginx/sbin/nginx -s reload
```

**方式 2: 使用 setcap**
```bash
# 查找 nginx 可执行文件位置
which nginx

# 给 nginx 添加权限
sudo setcap 'cap_net_bind_service=+ep' $(which nginx)
```

**方式 3: 在 .env 中配置 sudo**
```env
NGINX_PATH=sudo nginx
```

---

### 第六步: 配置防火墙和端口

#### 6.1 开放端口 (如果使用防火墙)

**Ubuntu/Debian (ufw):**
```bash
sudo ufw allow 3000/tcp
sudo ufw reload
```

**CentOS/RHEL (firewalld):**
```bash
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

#### 6.2 云服务器安全组配置

如果使用阿里云/腾讯云/AWS 等云服务器,需要在控制台配置安全组规则:
- 添加入站规则
- 协议: TCP
- 端口: 3000
- 源地址: 0.0.0.0/0 (或钉钉服务器 IP)

---

### 第七步: 启动服务

#### 7.1 测试启动
```bash
cd /opt/dingtalk-deploy-bot
npm run dev
```

查看是否有错误,如果正常启动,会看到:
```
========================================
钉钉部署机器人服务已启动
端口: 3000
环境: development
项目路径: /var/www/your-project
========================================
```

按 `Ctrl+C` 停止测试。

#### 7.2 生产环境启动 (使用 PM2)
```bash
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs deploy-bot

# 设置开机自启
pm2 startup
pm2 save
```

---

### 第八步: 配置钉钉 Webhook 地址

现在服务已经启动,需要让钉钉能访问到你的服务器。

#### 8.1 方式一: 使用公网 IP

如果服务器有公网 IP:
```
http://your-server-ip:3000/webhook/dingtalk
```

#### 8.2 方式二: 使用域名 + Nginx 反向代理 (推荐)

**配置 Nginx:**
```bash
sudo vim /etc/nginx/sites-available/deploy-bot
```

**Nginx 配置内容:**
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
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 增加超时时间
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

**启用配置:**
```bash
sudo ln -s /etc/nginx/sites-available/deploy-bot /etc/nginx/sites-enabled/
sudo nginx -t
sudo nginx -s reload
```

**然后 Webhook 地址为:**
```
http://deploy-bot.your-domain.com/webhook/dingtalk
```

#### 8.3 方式三: 使用内网穿透 (开发测试)

如果没有公网 IP,可以使用内网穿透工具:

**使用 ngrok:**
```bash
ngrok http 3000
```

复制 ngrok 提供的 URL,例如:
```
https://xxxx-xx-xx-xx-xx.ngrok.io/webhook/dingtalk
```

**注意**: 内网穿透适合测试,生产环境建议使用公网 IP 或域名。

---

### 第九步: 配置钉钉机器人 Webhook

1. 回到钉钉群,找到刚才创建的机器人
2. 点击机器人设置
3. 配置 Webhook 地址: `http://your-server/webhook/dingtalk`
4. 保存配置

---

### 第十步: 测试

#### 10.1 测试健康检查
```bash
curl http://your-server:3000/health
```

应该返回:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.456
}
```

#### 10.2 测试手动部署接口
```bash
curl -X POST http://your-server:3000/deploy
```

应该会收到钉钉消息通知。

#### 10.3 测试钉钉机器人

在钉钉群里 @机器人,发送任意消息:
```
@部署助手 发布新版本
```

机器人应该会回复并开始执行部署流程。

---

## 🔍 故障排查

### 服务无法启动

**检查端口占用:**
```bash
lsof -i :3000
# 或
netstat -tunlp | grep 3000
```

**查看日志:**
```bash
pm2 logs deploy-bot
# 或
tail -f logs/deploy.log
```

### 钉钉没有收到消息

**检查 Webhook 配置:**
```bash
# 测试服务是否可访问
curl -X POST http://your-server:3000/webhook/dingtalk \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"test"}}'
```

**查看服务日志:**
```bash
pm2 logs deploy-bot
```

### 部署命令执行失败

**检查项目路径:**
```bash
ls -la /var/www/your-project
```

**手动测试命令:**
```bash
cd /var/www/your-project
git pull origin main
pnpm install
pnpm build
nginx -s reload
```

**查看部署日志:**
```bash
tail -f logs/deploy.log
```

---

## 📊 监控和维护

### 查看服务状态
```bash
pm2 status
pm2 monit
```

### 查看日志
```bash
# 实时日志
pm2 logs deploy-bot

# 错误日志
tail -f logs/error-*.log

# 部署日志
tail -f logs/deploy-*.log
```

### 重启服务
```bash
pm2 restart deploy-bot
```

### 更新机器人代码
```bash
cd /opt/dingtalk-deploy-bot
git pull
pnpm install
pm2 restart deploy-bot
```

---

## 🔒 安全建议

1. ✅ **必须启用**钉钉签名验证 (DINGTALK_SECRET)
2. ✅ **使用 HTTPS** (配置 SSL 证书)
3. ✅ **限制 sudo 权限**,只允许必要的命令
4. ✅ **定期更新**依赖包和系统
5. ✅ **备份重要数据**
6. ✅ **监控日志文件**大小,定期清理
7. ✅ **使用防火墙**限制访问
8. ✅ **不要在公共仓库**提交 .env 文件

---

## 📝 维护清单

### 每周
- [ ] 查看错误日志
- [ ] 检查磁盘空间

### 每月
- [ ] 更新依赖包: `pnpm update`
- [ ] 清理旧日志: `pm2 flush`
- [ ] 检查 PM2 状态

### 每季度
- [ ] 更新 Node.js 版本
- [ ] 审查安全配置
- [ ] 测试备份恢复流程

---

完成以上步骤后,你的钉钉部署机器人就部署完成了! 🎉

