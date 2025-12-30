#!/bin/bash

# 卸载脚本

set -e

echo "========================================="
echo "  钉钉部署机器人 - 卸载"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}警告: 此操作将停止并删除部署机器人服务${NC}"
echo ""
read -p "是否继续? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消卸载"
    exit 0
fi

# 停止 PM2 进程
echo ""
echo -e "${YELLOW}[1/4]${NC} 停止 PM2 进程..."
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "deploy-bot"; then
        pm2 delete deploy-bot
        echo -e "${GREEN}✓ PM2 进程已停止${NC}"
    else
        echo -e "${YELLOW}  PM2 进程不存在,跳过${NC}"
    fi
else
    echo -e "${YELLOW}  PM2 未安装,跳过${NC}"
fi

# 删除 PM2 启动配置
echo ""
echo -e "${YELLOW}[2/4]${NC} 清理 PM2 配置..."
pm2 save --force 2>/dev/null || true
echo -e "${GREEN}✓ PM2 配置已清理${NC}"

# 删除 Nginx 配置
echo ""
echo -e "${YELLOW}[3/4]${NC} 删除 Nginx 配置..."
if [ -f "/etc/nginx/sites-enabled/deploy-bot" ]; then
    read -p "是否删除 Nginx 配置? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -f /etc/nginx/sites-enabled/deploy-bot
        sudo rm -f /etc/nginx/sites-available/deploy-bot
        sudo nginx -s reload
        echo -e "${GREEN}✓ Nginx 配置已删除${NC}"
    else
        echo -e "${YELLOW}  跳过删除 Nginx 配置${NC}"
    fi
else
    echo -e "${YELLOW}  Nginx 配置不存在,跳过${NC}"
fi

# 清理文件
echo ""
echo -e "${YELLOW}[4/4]${NC} 清理文件..."
read -p "是否删除项目文件? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ..
    rm -rf dingtalk-deploy-bot
    echo -e "${GREEN}✓ 项目文件已删除${NC}"
else
    echo -e "${YELLOW}  保留项目文件${NC}"
    echo "  可手动删除: rm -rf $(pwd)"
fi

echo ""
echo "========================================="
echo -e "${GREEN}卸载完成!${NC}"
echo "========================================="
echo ""

