#!/bin/bash

# 钉钉部署机器人安装脚本
# 用法: bash install.sh

set -e  # 遇到错误立即退出

echo "========================================="
echo "  钉钉部署机器人 - 自动安装脚本"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then 
  echo -e "${RED}错误: 请不要使用 root 用户运行此脚本${NC}"
  exit 1
fi

# 检查 Node.js
echo -e "${YELLOW}[1/8]${NC} 检查 Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}错误: Node.js 未安装${NC}"
    echo "请先安装 Node.js >= 16.x"
    echo "推荐使用 nvm: https://github.com/nvm-sh/nvm"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo -e "${RED}错误: Node.js 版本过低 (当前: $(node -v), 需要: >= 16.x)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js 版本: $(node -v)${NC}"

# 检查 pnpm
echo -e "${YELLOW}[2/8]${NC} 检查 pnpm..."
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}pnpm 未安装,正在安装...${NC}"
    npm install -g pnpm
fi
echo -e "${GREEN}✓ pnpm 版本: $(pnpm -v)${NC}"

# 检查 Git
echo -e "${YELLOW}[3/8]${NC} 检查 Git..."
if ! command -v git &> /dev/null; then
    echo -e "${RED}错误: Git 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git 版本: $(git --version)${NC}"

# 检查 PM2
echo -e "${YELLOW}[4/8]${NC} 检查 PM2..."
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 未安装,正在安装...${NC}"
    npm install -g pm2
fi
echo -e "${GREEN}✓ PM2 版本: $(pm2 -v)${NC}"

# 安装依赖
echo -e "${YELLOW}[5/8]${NC} 安装项目依赖..."
pnpm install
echo -e "${GREEN}✓ 依赖安装完成${NC}"

# 创建日志目录
echo -e "${YELLOW}[6/8]${NC} 创建日志目录..."
mkdir -p logs
echo -e "${GREEN}✓ 日志目录已创建${NC}"

# 配置环境变量
echo -e "${YELLOW}[7/8]${NC} 配置环境变量..."
if [ ! -f .env ]; then
    cp env.example .env
    echo -e "${YELLOW}已创建 .env 文件,请编辑配置:${NC}"
    echo -e "  ${GREEN}vim .env${NC}"
    echo ""
    echo -e "必须配置以下参数:"
    echo -e "  - DINGTALK_SECRET    (钉钉机器人密钥)"
    echo -e "  - DINGTALK_WEBHOOK   (钉钉机器人 Webhook 地址)"
    echo -e "  - PROJECT_PATH       (要部署的项目路径)"
    echo ""
else
    echo -e "${GREEN}✓ .env 文件已存在${NC}"
fi

# 权限检查提示
echo -e "${YELLOW}[8/8]${NC} 权限配置提示..."
echo -e "${YELLOW}请确保配置以下权限:${NC}"
echo ""
echo -e "1. ${GREEN}项目目录权限:${NC}"
echo -e "   sudo chown -R \$(whoami):\$(whoami) /var/www/your-project"
echo ""
echo -e "2. ${GREEN}Nginx reload 权限 (选择一种方式):${NC}"
echo -e "   方式1: sudo visudo"
echo -e "   添加: \$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/nginx -s reload"
echo ""
echo -e "   方式2: 在 .env 中设置 NGINX_PATH=sudo nginx"
echo ""
echo -e "3. ${GREEN}Git SSH 密钥 (如果是私有仓库):${NC}"
echo -e "   ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\""
echo -e "   cat ~/.ssh/id_rsa.pub  # 添加到 GitHub/GitLab"
echo ""

# 安装完成
echo "========================================="
echo -e "${GREEN}安装完成!${NC}"
echo "========================================="
echo ""
echo "接下来的步骤:"
echo ""
echo -e "1. ${YELLOW}编辑配置文件:${NC}"
echo -e "   vim .env"
echo ""
echo -e "2. ${YELLOW}测试启动:${NC}"
echo -e "   npm run dev"
echo ""
echo -e "3. ${YELLOW}生产环境启动:${NC}"
echo -e "   pm2 start ecosystem.config.js"
echo ""
echo -e "4. ${YELLOW}查看日志:${NC}"
echo -e "   pm2 logs deploy-bot"
echo ""
echo -e "5. ${YELLOW}查看状态:${NC}"
echo -e "   pm2 status"
echo ""
echo -e "6. ${YELLOW}配置开机自启:${NC}"
echo -e "   pm2 startup"
echo -e "   pm2 save"
echo ""
echo "详细文档请查看: README.md 和 DEPLOY.md"
echo ""

