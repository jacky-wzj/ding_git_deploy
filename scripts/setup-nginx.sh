#!/bin/bash

# Nginx 反向代理配置脚本

set -e

echo "========================================="
echo "  配置 Nginx 反向代理"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否安装 Nginx
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}错误: Nginx 未安装${NC}"
    echo ""
    echo "请先安装 Nginx:"
    echo "  Ubuntu/Debian: sudo apt install nginx"
    echo "  CentOS/RHEL:   sudo yum install nginx"
    exit 1
fi

echo -e "${GREEN}✓ Nginx 已安装: $(nginx -v 2>&1)${NC}"
echo ""

# 获取用户输入
read -p "请输入域名 (例如: deploy-bot.example.com): " DOMAIN
read -p "请输入服务端口 (默认: 3000): " PORT
PORT=${PORT:-3000}

# 生成 Nginx 配置
NGINX_CONF="/etc/nginx/sites-available/deploy-bot"

echo ""
echo -e "${YELLOW}正在生成 Nginx 配置...${NC}"

sudo tee "$NGINX_CONF" > /dev/null <<EOF
# 钉钉部署机器人 - Nginx 配置
# 域名: $DOMAIN
# 生成时间: $(date)

server {
    listen 80;
    server_name $DOMAIN;

    # 日志
    access_log /var/log/nginx/deploy-bot.access.log;
    error_log /var/log/nginx/deploy-bot.error.log;

    # 反向代理
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        
        # WebSocket 支持
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        
        # 代理头
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 缓存控制
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 限流 (每分钟10个请求)
    limit_req_zone \$binary_remote_addr zone=deploy_limit:10m rate=10r/m;
    limit_req zone=deploy_limit burst=5;

    # 安全头
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
}
EOF

echo -e "${GREEN}✓ Nginx 配置已生成: $NGINX_CONF${NC}"

# 启用站点
echo ""
echo -e "${YELLOW}启用站点...${NC}"

if [ -d "/etc/nginx/sites-enabled" ]; then
    sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/deploy-bot"
    echo -e "${GREEN}✓ 站点已启用${NC}"
else
    echo -e "${YELLOW}! 你的系统不使用 sites-enabled 目录${NC}"
    echo -e "请手动在 nginx.conf 中包含配置文件:"
    echo -e "  include $NGINX_CONF;"
fi

# 测试配置
echo ""
echo -e "${YELLOW}测试 Nginx 配置...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
else
    echo -e "${RED}错误: Nginx 配置测试失败${NC}"
    exit 1
fi

# 重载 Nginx
echo ""
read -p "是否现在重载 Nginx? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo nginx -s reload
    echo -e "${GREEN}✓ Nginx 已重载${NC}"
fi

# SSL 提示
echo ""
echo "========================================="
echo -e "${GREEN}配置完成!${NC}"
echo "========================================="
echo ""
echo -e "${YELLOW}接下来的步骤:${NC}"
echo ""
echo "1. 确保域名已解析到服务器 IP"
echo "   检查: dig $DOMAIN +short"
echo ""
echo "2. 配置 SSL 证书 (推荐使用 Let's Encrypt):"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d $DOMAIN"
echo ""
echo "3. 在钉钉机器人中配置 Webhook 地址:"
echo "   http://$DOMAIN/webhook/dingtalk"
echo "   或 (配置 SSL 后):"
echo "   https://$DOMAIN/webhook/dingtalk"
echo ""
echo "4. 测试配置:"
echo "   curl http://$DOMAIN/health"
echo ""

