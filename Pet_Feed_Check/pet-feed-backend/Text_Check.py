import pickle

import faiss
import numpy as np
import requests

from LLM_Judge import Siliconflow
from config import INDEX_DIR, MODEL_MAP

index = faiss.read_index(f"{INDEX_DIR}/kb.index")
with open(f"{INDEX_DIR}/chunks.pkl", "rb") as f:
    chunks = pickle.load(f)


def get_embedding_from_api(text, api_key, max_length=500):
    url = "https://api.siliconflow.cn/v1/embeddings"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    if len(text) > max_length:
        text = text[:max_length]

    payload = {
        "model": "BAAI/bge-large-zh-v1.5",
        "input": text,
        "encoding_format": "float",
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        result = response.json()
        embedding = result["data"][0]["embedding"]
        return np.array([embedding], dtype=np.float32)
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Embedding API 请求失败: {e}")
        raise Exception(f"Embedding API 调用失败: {str(e)}")


def extract_key_info(product_text):
    key_patterns = [
        "全价",
        "成犬",
        "成猫",
        "幼犬",
        "幼猫",
        "原料",
        "配方",
        "添加剂",
        "成分",
        "粗蛋白",
        "粗脂肪",
        "水分",
        "灰分",
        "生产",
        "许可证",
        "执行标准",
        "储存",
        "保质期",
        "净含量",
    ]
    lines = product_text.split("\n")
    key_lines = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        for pattern in key_patterns:
            if pattern in line:
                key_lines.append(line)
                break
        if len(key_lines) >= 10:
            break
    if len(key_lines) < 3:
        return product_text[:300]
    return "\n".join(key_lines)[:500]


def rag_retrieve(query, api_key, top_k=5):
    short_query = extract_key_info(query)
    q_vec = get_embedding_from_api(short_query, api_key, max_length=500)
    faiss.normalize_L2(q_vec)
    _, indices = index.search(q_vec, top_k)
    return [chunks[i]["text"] for i in indices[0]]


def build_prompt(product_text, refs):
    refs_text = "\n\n".join([f"{i + 1}. {r}" for i, r in enumerate(refs)])
    return f"""
你是一名【宠物饲料产品合规执法辅助AI】。

请你仅依据给定【法规资料】，对【待判定文本】进行合规性审查，
不得进行主观臆断，不得引用资料以外内容，不得修改【输出模板】，不得输出【输出模板】不包含的任何文字。

请直接严格按照以下【输出模板】输出：

【合规判定】合规 / 不合规
【违规点】逐条列出，如无则写"未发现违规点"
【法条依据】写明法规名称 + 条款要点
【执法提示】给出可执行的监管建议

====================
【法规资料】
{refs_text}

====================
【待判定文本】
{product_text}
"""


def resolve_model_name(model):
    if model in MODEL_MAP:
        return MODEL_MAP[model]

    if isinstance(model, str) and "/" in model:
        return model

    print(f"[WARN] 未知模型 '{model}'，使用默认模型 DeepSeek-R1")
    return MODEL_MAP.get("DeepSeek-R1", "Pro/deepseek-ai/DeepSeek-R1")


def judge(product_text, api_keys, model, DEBUG=False):
    if isinstance(api_keys, list):
        api_key = api_keys[0]
    else:
        api_key = api_keys
    try:
        refs = rag_retrieve(product_text, api_key, top_k=6)
    except Exception as e:
        print(f"[WARN] RAG 检索失败，使用空法规资料: {e}")
        refs = []
    prompt = build_prompt(product_text, refs)
    resolved_model = resolve_model_name(model)
    if DEBUG:
        print("【Model最终调用】\n" + resolved_model)
        print("【Prompt最终构建】\n" + prompt)
    model_output = Siliconflow(api_key, [prompt], resolved_model, DEBUG)
    return model_output


if __name__ == "__main__":
    from config import LLM_TOKEN

    product_text = """
    # 鸡肉鸭肉双拼

# · 全价成犬鲜食 ·

原料配方：鲜鸡胸肉32%，鲜鸭胸肉20%，鲜牛肉8%，鸡胗3%，鸡心2%，鸡肝1%，有机南瓜，有机西蓝花，有机球甘蓝，有机胡萝卜，南极磷虾油，软磷脂

☐ 添加剂：轻质碳酸钙、磷酸氢钙

☐ 产品成分分析保证值(以干物质计/%):

粗蛋白 ≥66% 钙 ≥1.3%
粗脂肪 ≥10% 总磷 ≥1.1%
粗灰分 ≤9.5% 赖氨酸 ≥5.12%
粗纤维 ≤2.3% 水溶性氯化物(以Cl⁻计) ≥0.4%
水分 ≥74.1%

生产信息：品牌方：上海鲜卡福宠物食品有限公司；生产企业汕尾市维明生物科技有限公司；生产许可证号：粤司证（2022）10001；

储存条件：-18℃冷冻储存
    """

    model_name = "Qwen3-VL"
    debug = True

    audit_result = judge(product_text, LLM_TOKEN, model_name, debug)
    print("【Check_Result】\n" + audit_result)
