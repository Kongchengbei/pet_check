# 使用官方 Python 3.10 基础镜像
FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 复制 requirements.txt
COPY requirements.txt .

# 升级 pip 并安装依赖（使用阿里云镜像）
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
    -i https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com \
    -r requirements.txt

# 复制所有项目文件
COPY . .

# 创建必要的目录
RUN mkdir -p /app/temp_images

# 暴露端口
EXPOSE 80

# 启动命令
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "2", "--timeout", "180", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
