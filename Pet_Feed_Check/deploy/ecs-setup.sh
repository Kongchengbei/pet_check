#!/bin/bash
# ============================================
# 阿里云 ECS 初始化脚本 (Ubuntu 22.04)
# 运行: sudo bash ecs-setup.sh
# ============================================

set -e

echo "=== 更新系统包 ==="
apt-get update && apt-get upgrade -y

echo "=== 安装 Docker ==="
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 启动 Docker ==="
systemctl enable docker
systemctl start docker

echo "=== 安装 Nginx ==="
apt-get install -y nginx

echo "=== 配置防火墙 ==="
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw --force enable

echo "=== 创建应用目录 ==="
mkdir -p /opt/pet-feed-backend/temp_images
mkdir -p /opt/pet-feed-backend/tasks

echo "=== 完成 ==="
echo "请将项目文件上传到 /opt/pet-feed-backend/"
echo "然后运行: cd /opt/pet-feed-backend && docker compose up -d"
