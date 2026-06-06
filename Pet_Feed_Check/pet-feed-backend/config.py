"""
配置文件 - 适配云托管环境变量
"""
import os


def _read_env(name, default=""):
    value = os.environ.get(name, default)
    if isinstance(value, str):
        return value.strip()
    return value


# API Tokens
OCR_TOKEN = _read_env("OCR_TOKEN")
LLM_TOKEN = _read_env("LLM_TOKEN")

# 服务器配置
HOST = "0.0.0.0"
PORT = int(os.environ.get("PORT", 80))
DEBUG = os.environ.get("DEBUG", "False").lower() == "true"

# 测试图片路径
TEST_PATH = "Utils/demo/test.jpg"

# 模型配置（仅保留 LLM 模型映射）
INDEX_DIR = "Utils/index"
DEFAULT_QWEN3_NEXT_MODEL = os.environ.get(
    "QWEN3_NEXT_MODEL",
    os.environ.get("QWEN3_MODEL", "Qwen/Qwen3-VL-30B-A3B-Thinking"),
)
MODEL_MAP = {
    "DeepSeek-R1": "Pro/deepseek-ai/DeepSeek-R1",
    "DeepSeek-V3.2": "Pro/deepseek-ai/DeepSeek-V3.2",
    "Qwen3-Next": DEFAULT_QWEN3_NEXT_MODEL,
    "GLM-4.7": "Pro/zai-org/GLM-4.7",
    "MiniMax-M2": "MiniMaxAI/MiniMax-M2",
}

# Embedding API 配置（使用 SiliconFlow）
EMBEDDING_MODEL = "BAAI/bge-large-zh-v1.5"
EMBEDDING_API_URL = "https://api.siliconflow.cn/v1/embeddings"

# LLM 调用配置
LLM_CONNECT_TIMEOUT = int(os.environ.get("LLM_CONNECT_TIMEOUT", 15))
LLM_READ_TIMEOUT = int(os.environ.get("LLM_READ_TIMEOUT", 180))
LLM_MAX_RETRIES = int(os.environ.get("LLM_MAX_RETRIES", 3))
LLM_RETRY_BACKOFF_SECONDS = int(os.environ.get("LLM_RETRY_BACKOFF_SECONDS", 2))

# 图片临时存储目录
UPLOAD_FOLDER = os.environ.get("UPLOAD_FOLDER", "./temp_images")

print("Config:")
print(f"   PORT: {PORT}")
print(f"   DEBUG: {DEBUG}")
print(f"   QWEN3_NEXT_MODEL: {DEFAULT_QWEN3_NEXT_MODEL}")
print(f"   LLM_TIMEOUT: connect={LLM_CONNECT_TIMEOUT}s read={LLM_READ_TIMEOUT}s retries={LLM_MAX_RETRIES}")
