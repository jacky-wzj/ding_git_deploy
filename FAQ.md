# 常见问题解答 (FAQ)

## 📋 目录

- [安装问题](#安装问题)
- [配置问题](#配置问题)
- [运行问题](#运行问题)
- [部署问题](#部署问题)
- [钉钉问题](#钉钉问题)
- [权限问题](#权限问题)
- [性能问题](#性能问题)

---

## 安装问题

### Q1: Node.js 版本不符合要求怎么办?

**A:** 使用 nvm 管理 Node.js 版本:

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# 安装并使用 Node.js 18
nvm install 18
nvm use 18
nvm alias default 18
```

### Q2: pnpm 安装失败?

**A:** 尝试以下方法:

```bash
# 方法1: 使用 npm 安装
npm install -g pnpm

# 方法2: 使用官方脚本
curl -fsSL https://get.pnpm.io/install.sh | sh -

# 方法3: 使用 npm 的 npx
npx pnpm install
```

### Q3: PM2 命令找不到?

**A:** 确保全局安装并添加到 PATH:

```bash
npm install -g pm2

# 如果还是找不到,手动添加到 PATH
export PATH=$PATH:~/.npm-global/bin
# 或
export PATH=$PATH:/usr/local/bin
```

---

## 配置问题

### Q4: 钉钉机器人密钥在哪里找?

**A:** 创建钉钉机器人时会显示:

1. 钉钉群 → **群设置** → **智能群助手** → **添加机器人**
2. 选择 **自定义机器人**
3. 在 **安全设置** 中选择 **加签**
4. 复制显示的密钥 (格式: SECxxxx...)

**注意:** 密钥只显示一次,务必保存好!

### Q5: Webhook 地址配置错误?

**A:** Webhook 地址格式:

```
http://your-server-ip:3000/webhook/dingtalk
```

或使用域名:

```
http://deploy-bot.your-domain.com/webhook/dingtalk
```

**注意事项:**
- 必须是公网可访问的地址
- 路径必须是 `/webhook/dingtalk`
- 如果使用 Nginx,确保反向代理配置正确

### Q6: 项目路径配置错误?

**A:** `PROJECT_PATH` 应该是要部署的项目路径,**不是**机器人自己的路径!

```env
# ❌ 错误
PROJECT_PATH=/opt/dingtalk-deploy-bot

# ✅ 正确 (你要部署的实际项目)
PROJECT_PATH=/var/www/your-project
PROJECT_PATH=/home/user/projects/my-website
```

---

## 运行问题

### Q7: 服务启动失败,报端口被占用?

**A:** 查找并关闭占用端口的进程:

```bash
# 查找占用 3000 端口的进程
lsof -i :3000

# 关闭进程
kill -9 <PID>

# 或修改端口
vim .env
# PORT=3001
```

### Q8: PM2 启动后服务立即停止?

**A:** 检查错误日志:

```bash
# 查看日志
pm2 logs deploy-bot

# 查看详细信息
pm2 describe deploy-bot

# 常见原因:
# 1. .env 文件配置错误
# 2. 依赖未安装: pnpm install
# 3. 语法错误: node src/index.js 测试
```

### Q9: 服务运行一段时间后自动停止?

**A:** 检查内存使用和错误:

```bash
# 查看 PM2 监控
pm2 monit

# 增加最大内存限制
pm2 start ecosystem.config.js --max-memory-restart 1G

# 查看系统资源
free -h
df -h
```

---

## 部署问题

### Q10: 部署命令执行失败?

**A:** 逐步手动测试每个命令:

```bash
# 切换到项目目录
cd /var/www/your-project

# 1. 测试 git pull
git pull origin main

# 2. 测试 pnpm install
pnpm install --prod=false

# 3. 测试 pnpm build
pnpm build

# 4. 测试 nginx reload
nginx -s reload
# 或
sudo nginx -s reload
```

找出哪一步失败,然后查看具体错误。

### Q11: Git pull 提示权限错误?

**A:** 配置 SSH 密钥:

```bash
# 生成密钥
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 复制公钥
cat ~/.ssh/id_rsa.pub

# 添加到 GitHub/GitLab/Gitee
# Settings → SSH Keys → Add SSH Key

# 测试连接
ssh -T git@github.com
```

### Q12: pnpm build 失败?

**A:** 检查以下几点:

```bash
# 1. 检查 Node.js 版本
node -v

# 2. 清理缓存重新安装
rm -rf node_modules
rm -rf pnpm-lock.yaml
pnpm install

# 3. 检查磁盘空间
df -h

# 4. 查看构建日志
pnpm build --verbose
```

### Q13: Nginx reload 权限不足?

**A:** 三种解决方案:

**方案 1: 配置 sudo 免密 (推荐)**
```bash
sudo visudo

# 添加 (替换 your-user 为实际用户名):
your-user ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload
```

**方案 2: 在 .env 中使用 sudo**
```env
NGINX_PATH=sudo nginx
```

**方案 3: 修改 Nginx 权限**
```bash
sudo setcap 'cap_net_bind_service=+ep' $(which nginx)
```

---

## 钉钉问题

### Q14: @机器人 没有反应?

**A:** 检查以下几点:

1. **服务是否运行:**
```bash
pm2 status
curl http://localhost:3000/health
```

2. **Webhook 地址是否正确:**
```bash
# 测试 webhook 是否可访问
curl -X POST http://your-server:3000/webhook/dingtalk \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"test"}}'
```

3. **查看服务日志:**
```bash
pm2 logs deploy-bot
tail -f logs/deploy.log
```

4. **检查防火墙和安全组:**
```bash
# 查看防火墙状态
sudo ufw status
sudo firewall-cmd --list-all

# 开放端口
sudo ufw allow 3000/tcp
```

### Q15: 钉钉提示签名验证失败?

**A:** 检查密钥配置:

```bash
# 1. 查看 .env 中的密钥
cat .env | grep DINGTALK_SECRET

# 2. 确保格式正确 (以 SEC 开头)
DINGTALK_SECRET=SECxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. 重启服务
pm2 restart deploy-bot
```

### Q16: 钉钉消息发送失败?

**A:** 检查 Webhook 配置:

```bash
# 1. 检查 Webhook 地址
cat .env | grep DINGTALK_WEBHOOK

# 2. 测试 Webhook
curl -X POST "your-webhook-url" \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"测试消息"}}'

# 3. 查看服务日志
pm2 logs deploy-bot
```

---

## 权限问题

### Q17: 无法写入项目目录?

**A:** 修改目录权限:

```bash
# 方法1: 修改所有者
sudo chown -R $(whoami):$(whoami) /var/www/your-project

# 方法2: 修改权限
sudo chmod -R 755 /var/www/your-project

# 方法3: 添加到用户组
sudo usermod -a -G www-data $(whoami)
```

### Q18: Git 操作权限错误?

**A:** 确保 Git 配置正确:

```bash
# 1. 检查远程仓库
cd /var/www/your-project
git remote -v

# 2. 如果是 HTTPS,切换到 SSH
git remote set-url origin git@github.com:user/repo.git

# 3. 配置 Git 用户信息
git config user.name "Your Name"
git config user.email "your@email.com"
```

### Q19: Nginx 配置测试失败?

**A:** 检查 Nginx 配置:

```bash
# 1. 测试配置
sudo nginx -t

# 2. 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 3. 检查配置文件语法
sudo vim /etc/nginx/sites-available/deploy-bot
```

---

## 性能问题

### Q20: 部署时间太长?

**A:** 优化方案:

1. **使用缓存:**
```bash
# pnpm 使用缓存
pnpm install --prefer-offline
```

2. **并行构建:**
```bash
# 多核并行构建
pnpm build --max-workers 4
```

3. **增量构建:**
```bash
# 只构建变更的部分
pnpm build --incremental
```

### Q21: 服务器内存占用高?

**A:** 优化内存使用:

```bash
# 1. 限制 PM2 内存
pm2 start ecosystem.config.js --max-memory-restart 500M

# 2. 减少 PM2 实例
pm2 scale deploy-bot 1

# 3. 清理日志
pm2 flush

# 4. 查看内存使用
pm2 monit
free -h
```

### Q22: 日志文件太大?

**A:** 日志已自动轮转,但可以手动清理:

```bash
# 1. 查看日志大小
du -sh logs/

# 2. 清理旧日志
find logs/ -name "*.log" -mtime +7 -delete

# 3. 清理 PM2 日志
pm2 flush

# 4. 配置定时清理
crontab -e
# 添加: 0 0 * * 0 find /path/to/logs -mtime +30 -delete
```

---

## 其他问题

### Q23: 如何回滚到上一个版本?

**A:** 手动回滚:

```bash
cd /var/www/your-project

# 1. 查看提交历史
git log --oneline -10

# 2. 回滚到指定版本
git reset --hard <commit-id>

# 3. 重新部署
pnpm install
pnpm build
nginx -s reload
```

### Q24: 如何部署多个项目?

**A:** 两种方案:

**方案 1: 多实例 (推荐)**
```bash
# 项目 A
PORT=3001 PROJECT_PATH=/var/www/project-a pm2 start src/index.js --name deploy-a

# 项目 B
PORT=3002 PROJECT_PATH=/var/www/project-b pm2 start src/index.js --name deploy-b
```

**方案 2: 修改代码支持多项目**
```javascript
// 根据 URL 路径区分项目
app.post('/webhook/dingtalk/:project', ...)
```

### Q25: 如何添加邮件通知?

**A:** 修改 `src/dingtalk.js`,添加邮件发送逻辑:

```javascript
const nodemailer = require('nodemailer');

async function sendEmail(subject, content) {
  const transporter = nodemailer.createTransport({
    host: 'smtp.example.com',
    port: 587,
    auth: {
      user: 'your-email@example.com',
      pass: 'your-password'
    }
  });

  await transporter.sendMail({
    from: 'deploy-bot@example.com',
    to: 'admin@example.com',
    subject: subject,
    text: content
  });
}
```

---

## 💬 获取帮助

如果以上 FAQ 无法解决你的问题:

1. 查看详细日志:
```bash
pm2 logs deploy-bot --lines 100
tail -f logs/deploy.log
tail -f logs/error.log
```

2. 查看系统日志:
```bash
sudo journalctl -u nginx -f
dmesg | tail
```

3. 提交 Issue (附上以下信息):
   - 操作系统和版本
   - Node.js 版本
   - 错误日志
   - 配置文件 (隐藏敏感信息)

---

**最后更新:** 2024-12-30

