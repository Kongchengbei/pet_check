import base64
import requests
import time
import urllib3
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def create_session():
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[500, 502, 503, 504]
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def imgmd_OCR(image_path, api_key, max_retries=3):
    with open(image_path, "rb") as f:
        file_data = base64.b64encode(f.read()).decode("ascii")
    API_URL = "https://3fje38c9y7h6y3f7.aistudio-app.com/layout-parsing"
    headers = {
        "Authorization": f"token {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "file": file_data,
        "fileType": 1,  # 0: PDF, 1: image
        "markdownIgnoreLabels": [
            "header",
            "header_image",
            "footer",
            "footer_image",
            "number",
            "footnote",
            "aside_text"
        ],
        "useDocOrientationClassify": True,
        "useDocUnwarping": True,
        "useLayoutDetection": True,
        "useChartRecognition": True,
        "promptLabel": "ocr",
        "repetitionPenalty": 1,
        "temperature": 0,
        "topP": 1,
        "minPixels": 147384,
        "maxPixels": 2822400,
        "layoutNms": True
    }
    session = create_session()
    last_error = None
    for attempt in range(max_retries):
        try:
            verify_ssl = True if attempt == 0 else False

            if attempt > 0:
                print(f"⚠️ 第 {attempt + 1} 次重试{'（禁用SSL验证）' if not verify_ssl else ''}...")
            response = session.post(
                API_URL,
                json=payload,
                headers=headers,
                timeout=(15, 120),  # 连接15秒，读取120秒
                verify=verify_ssl
            )
            response.raise_for_status()
            result = response.json()["result"]["layoutParsingResults"]
            markdown_texts = []
            for res in result:
                markdown_texts.append(res["markdown"]["text"])
            return "\n\n".join(markdown_texts)
        except requests.exceptions.SSLError as e:
            last_error = e
            print(f"⚠️ SSL 错误 (尝试 {attempt + 1}/{max_retries}): {str(e)[:100]}")
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f"   等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
        except requests.exceptions.Timeout as e:
            last_error = e
            print(f"⚠️ 请求超时 (尝试 {attempt + 1}/{max_retries})")
            if attempt < max_retries - 1:
                time.sleep(2)
        except requests.exceptions.HTTPError as e:
            status_code = e.response.status_code if e.response else None
            if status_code == 403:
                raise Exception("OCR Token 无效或已过期，请重新获取")
            elif status_code == 401:
                raise Exception("OCR 认证失败，请检查 Token 格式")
            elif status_code == 400:
                raise Exception(f"请求格式错误: {e.response.text[:200]}")
            else:
                last_error = e
                print(f"⚠️ HTTP 错误 {status_code} (尝试 {attempt + 1}/{max_retries})")

                if attempt < max_retries - 1:
                    time.sleep(2)
        except requests.exceptions.ConnectionError as e:
            last_error = e
            print(f"⚠️ 连接错误 (尝试 {attempt + 1}/{max_retries}): {str(e)[:100]}")
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f"   等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
        except KeyError as e:
            raise Exception(f"OCR 返回格式异常，缺少字段: {e}")
        except Exception as e:
            last_error = e
            print(f"⚠️ 未知错误 (尝试 {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                time.sleep(2)
    raise Exception(f"OCR 服务请求失败（已重试 {max_retries} 次）: {last_error}")


if __name__ == "__main__":
    from config import OCR_TOKEN, TEST_PATH
    TOKEN = OCR_TOKEN
    image_path = TEST_PATH
    try:
        md_content = imgmd_OCR(image_path, TOKEN)
        print("✅ OCR 识别成功")
        print("=" * 50)
        print(md_content)
    except Exception as e:
        print(f"❌ OCR 识别失败: {e}")