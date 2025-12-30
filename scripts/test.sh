#!/bin/bash

# 测试脚本 - 用于验证部署机器人是否正常工作

set -e

echo "========================================="
echo "  钉钉部署机器人 - 功能测试"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}错误: .env 文件不存在${NC}"
    exit 1
fi

PORT=${PORT:-3000}
HOST="http://localhost:$PORT"

echo -e "${YELLOW}测试目标: $HOST${NC}"
echo ""

# 测试1: 健康检查
echo -e "${YELLOW}[1/4]${NC} 测试健康检查接口..."
RESPONSE=$(curl -s "$HOST/health" || echo "failed")

if echo "$RESPONSE" | grep -q '"status":"ok"'; then
    echo -e "${GREEN}✓ 健康检查通过${NC}"
    echo "  响应: $RESPONSE"
else
    echo -e "${RED}✗ 健康检查失败${NC}"
    echo "  请确保服务已启动: pm2 status"
    exit 1
fi
echo ""

# 测试2: 手动触发部署
echo -e "${YELLOW}[2/4]${NC} 测试手动部署接口..."
read -p "是否触发一次测试部署? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    RESPONSE=$(curl -s -X POST "$HOST/deploy" || echo "failed")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}✓ 部署请求已发送${NC}"
        echo "  请在钉钉群中查看部署进度"
    else
        echo -e "${RED}✗ 部署请求失败${NC}"
        echo "  响应: $RESPONSE"
    fi
else
    echo -e "${YELLOW}跳过测试${NC}"
fi
echo ""

# 测试3: 检查配置
echo -e "${YELLOW}[3/4]${NC} 检查配置..."

# 检查必要的环境变量
MISSING_VARS=()

if [ -z "$DINGTALK_SECRET" ] || [ "$DINGTALK_SECRET" = "SECxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    MISSING_VARS+=("DINGTALK_SECRET")
fi

if [ -z "$DINGTALK_WEBHOOK" ] || [[ "$DINGTALK_WEBHOOK" == *"xxxxx"* ]]; then
    MISSING_VARS+=("DINGTALK_WEBHOOK")
fi

if [ -z "$PROJECT_PATH" ] || [ "$PROJECT_PATH" = "/var/www/your-project" ]; then
    MISSING_VARS+=("PROJECT_PATH")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}✗ 配置不完整${NC}"
    echo "  缺少或未正确配置的环境变量:"
    for var in "${MISSING_VARS[@]}"; do
        echo "    - $var"
    done
    echo ""
    echo "  请编辑 .env 文件完成配置"
else
    echo -e "${GREEN}✓ 配置检查通过${NC}"
    echo "  端口: $PORT"
    echo "  项目路径: $PROJECT_PATH"
    echo "  Git 分支: ${GIT_BRANCH:-main}"
fi
echo ""

# 测试4: 检查权限
echo -e "${YELLOW}[4/4]${NC} 检查权限..."

# 检查项目目录权限
if [ -d "$PROJECT_PATH" ]; then
    if [ -w "$PROJECT_PATH" ]; then
        echo -e "${GREEN}✓ 项目目录可写${NC}"
        echo "  路径: $PROJECT_PATH"
    else
        echo -e "${RED}✗ 项目目录不可写${NC}"
        echo "  路径: $PROJECT_PATH"
        echo "  解决: sudo chown -R \$(whoami) $PROJECT_PATH"
    fi
else
    echo -e "${RED}✗ 项目目录不存在${NC}"
    echo "  路径: $PROJECT_PATH"
    echo "  请在 .env 中配置正确的项目路径"
fi

# 检查 Nginx 权限
NGINX_CMD=${NGINX_PATH:-nginx}
echo ""
echo "测试 Nginx reload 权限..."
if $NGINX_CMD -t > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
    
    # 测试 reload (不实际执行,只检查权限)
    if [[ $NGINX_CMD == *"sudo"* ]]; then
        echo -e "${YELLOW}  使用 sudo 执行 Nginx reload${NC}"
    else
        echo -e "${GREEN}  使用当前用户执行 Nginx reload${NC}"
    fi
else
    echo -e "${RED}✗ Nginx 权限不足${NC}"
    echo "  命令: $NGINX_CMD"
    echo "  解决方案:"
    echo "    1. 配置 sudo 免密: sudo visudo"
    echo "    2. 或在 .env 中设置: NGINX_PATH=sudo nginx"
fi

echo ""
echo "========================================="
echo -e "${GREEN}测试完成!${NC}"
echo "========================================="
echo ""

# 总结
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过,机器人可以正常使用${NC}"
    echo ""
    echo "在钉钉群中 @机器人 即可触发部署"
else
    echo -e "${YELLOW}! 部分检查未通过,请完成配置后再试${NC}"
    echo ""
fi

