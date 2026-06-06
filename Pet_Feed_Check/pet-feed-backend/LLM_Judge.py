import json
import os
import time

import requests
from requests.exceptions import ReadTimeout, RequestException

from config import (
    LLM_CONNECT_TIMEOUT,
    LLM_MAX_RETRIES,
    LLM_READ_TIMEOUT,
    LLM_RETRY_BACKOFF_SECONDS,
)


def _build_messages(content_list):
    if isinstance(content_list, str):
        return [{"role": "user", "content": content_list}]

    if not isinstance(content_list, list):
        raise TypeError("content_list must be a string or a list")

    if content_list and isinstance(content_list[0], dict):
        return content_list

    return [
        {"role": "user" if i % 2 == 0 else "assistant", "content": content}
        for i, content in enumerate(content_list)
    ]


def _format_error_message(response_dict, model, status_code=None):
    if isinstance(response_dict, dict):
        error = response_dict.get("error")
        if isinstance(error, dict):
            message = error.get("message") or error.get("type") or json.dumps(error, ensure_ascii=False)
            code = error.get("code")
        else:
            message = response_dict.get("message") or response_dict.get("detail")
            code = response_dict.get("code")

        if message:
            code_text = f"code={code}, " if code is not None else ""
            status_text = f"HTTP {status_code}, " if status_code is not None else ""
            return f"[ERROR] LLM调用失败（{model}）：{status_text}{code_text}message={message}"

    if status_code is not None:
        return f"[ERROR] LLM调用失败（{model}）：HTTP {status_code}"
    return f"[ERROR] LLM调用失败（{model}）：未知错误"


def _post_with_retry(url, payload, headers, model):
    last_error = None

    # 创建不使用代理的 session（解决代理连接失败问题）
    session = requests.Session()
    session.trust_env = False  # 忽略环境变量中的代理设置

    for attempt in range(1, LLM_MAX_RETRIES + 1):
        try:
            response = session.post(
                url,
                json=payload,
                headers=headers,
                timeout=(LLM_CONNECT_TIMEOUT, LLM_READ_TIMEOUT),
            )
            return response, response.json()
        except ReadTimeout as e:
            last_error = (
                f"[ERROR] LLM调用失败（{model}）：读取超时，"
                f"已重试 {attempt}/{LLM_MAX_RETRIES} 次，"
                f"timeout={LLM_READ_TIMEOUT}s，error={str(e)}"
            )
        except RequestException as e:
            return None, f"[ERROR] LLM调用失败（{model}）：{str(e)}"
        except ValueError:
            return None, f"[ERROR] LLM调用失败（{model}）：响应不是合法 JSON"

        if attempt < LLM_MAX_RETRIES:
            time.sleep(LLM_RETRY_BACKOFF_SECONDS * attempt)

    return None, last_error or f"[ERROR] LLM调用失败（{model}）：未知网络错误"


def _chat_completions_request(api_key, content_list, model, url, provider_name, DEBUG=False):
    if isinstance(api_key, list):
        api_key = api_key[0]

    if not api_key:
        return f"[ERROR] LLM调用失败（{model}）：{provider_name} API key 未配置"

    messages = _build_messages(content_list)
    payload = {
        "model": model,
        "messages": messages,
        "stream": False,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    response, response_or_error = _post_with_retry(url, payload, headers, model)
    if response is None:
        return response_or_error

    response_dict = response_or_error

    if DEBUG:
        print(f"{model}:{response_dict}")

    if not response.ok:
        return _format_error_message(response_dict, model, response.status_code)

    choices = response_dict.get("choices")
    if not choices:
        return _format_error_message(response_dict, model, response.status_code)

    message = choices[0].get("message", {})
    result = message.get("content")
    if result is None:
        return _format_error_message(response_dict, model, response.status_code)

    return result


def Siliconflow(api_key, content_list, model="Pro/deepseek-ai/DeepSeek-R1", DEBUG=False):
    return _chat_completions_request(
        api_key,
        content_list,
        model,
        "https://api.siliconflow.cn/v1/chat/completions",
        "SiliconFlow",
        DEBUG,
    )


if __name__ == "__main__":
    from config import LLM_TOKEN

    api_key = LLM_TOKEN
    model = "Qwen/Qwen3-VL-30B-A3B-Thinking"
    content_list = ["请问你是谁？"]
    debug = True

    mess1 = Siliconflow(api_key, content_list, model, debug)
    content_list.append(mess1)
    content_list.append("介绍一下 AI 对时代的发展")
    mess2 = Siliconflow(api_key, content_list, model, debug)
    content_list.append(mess2)

    print(content_list)
