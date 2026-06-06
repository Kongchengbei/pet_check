import os
import time
import uuid
import json
import threading
import base64
import logging
import requests
from PIL import Image
from flask import request, jsonify, send_from_directory
from config import DEBUG, UPLOAD_FOLDER
from Pet_Feed import run_audit

logger = logging.getLogger(__name__)

TASK_FOLDER = "./tasks"
TASK_EXPIRE_TIME = 600

for folder in [UPLOAD_FOLDER, TASK_FOLDER]:
    os.makedirs(folder, exist_ok=True)

def _task_path(task_id):
    return os.path.join(TASK_FOLDER, f"{task_id}.json")

def _save_task(task_id, data):
    with open(_task_path(task_id), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def _load_task(task_id):
    path = _task_path(task_id)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def _update_task(task_id, patch):
    task = _load_task(task_id)
    if not task:
        return
    task.update(patch)
    _save_task(task_id, task)

def _cleanup_tasks():
    now = time.time()
    for f in os.listdir(TASK_FOLDER):
        if not f.endswith(".json"):
            continue
        path = os.path.join(TASK_FOLDER, f)
        if now - os.path.getmtime(path) > TASK_EXPIRE_TIME:
            os.remove(path)

def _download_image(url, save_path):
    r = requests.get(url, timeout=30, stream=True)
    r.raise_for_status()
    with open(save_path, "wb") as f:
        for chunk in r.iter_content(8192):
            f.write(chunk)

def _save_base64_image(b64, save_path):
    if "," in b64:
        b64 = b64.split(",")[1]
    data = base64.b64decode(b64)
    with open(save_path, "wb") as f:
        f.write(data)

def _stitch_images_vertically(image_paths, output_path):
    if not image_paths:
        raise ValueError("图片列表不能为空")

    images = [Image.open(path) for path in image_paths]

    max_width = max(img.width for img in images)
    total_height = sum(img.height for img in images)
    stitched_image = Image.new('RGB', (max_width, total_height), (255, 255, 255))

    y_offset = 0
    for img in images:
        x_offset = (max_width - img.width) // 2
        stitched_image.paste(img, (x_offset, y_offset))
        y_offset += img.height
    stitched_image.save(output_path, quality=95)

    for img in images:
        img.close()

    logger.info(f"✅ 成功拼接 {len(images)} 张图片")

def _audit_worker(task_id, image_path, model, level):
    try:
        _update_task(task_id, {
            "status": "processing",
            "started_at": time.time()
        })

        result = run_audit(image_path, model, DEBUG, level)

        _update_task(task_id, {
            "status": "completed",
            "result": result,
            "completed_at": time.time()
        })

    except Exception as e:
        logger.exception("审核失败")
        _update_task(task_id, {
            "status": "failed",
            "error": str(e)
        })
    finally:
        if os.path.exists(image_path):
            os.remove(image_path)

def api_index():
    return jsonify(
        service="宠物食品标签审核服务",
        version="local-debug",
        endpoints={
            "upload": "POST /api/upload",
            "audit": "POST /api/audit",
            "task": "GET /api/task/<task_id>",
            "uploads": "GET /uploads/<filename>"
        }
    )


def api_health():
    return jsonify(
        status="ok",
        active_tasks=len(os.listdir(TASK_FOLDER))
    )


def api_upload_file():
    if "file" not in request.files:
        return jsonify(success=False, message="未检测到文件"), 400

    file = request.files["file"]
    filename = f"{uuid.uuid4().hex}.jpg"
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)

    return jsonify(
        success=True,
        data={
            "filename": filename,
            "url": f"http://localhost:5000/uploads/{filename}"
        }
    )


def api_serve_upload(filename):
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    if not os.path.exists(file_path):
        return jsonify(success=False, message="文件不存在"), 404

    return send_from_directory(
        UPLOAD_FOLDER,
        filename,
        as_attachment=False
    )


def api_audit_image():
    _cleanup_tasks()

    data = request.get_json()
    if not data:
        return jsonify(success=False, message="请求体为空"), 400

    task_id = uuid.uuid4().hex[:8]

    file_urls = data.get("fileURLs", [])
    images_base64 = data.get("images", [])

    if data.get("fileURL"):
        file_urls = [data.get("fileURL")]
    if data.get("image"):
        images_base64 = [data.get("image")]

    if not file_urls and not images_base64:
        return jsonify(success=False, message="未提供图片数据"), 400

    temp_image_paths = []

    try:

        for idx, url in enumerate(file_urls):
            temp_path = os.path.join(UPLOAD_FOLDER, f"{task_id}_temp_{idx}.jpg")
            _download_image(url, temp_path)
            temp_image_paths.append(temp_path)

        for idx, b64 in enumerate(images_base64):
            temp_path = os.path.join(UPLOAD_FOLDER, f"{task_id}_temp_{len(file_urls) + idx}.jpg")
            _save_base64_image(b64, temp_path)
            temp_image_paths.append(temp_path)

        stitched_image_path = os.path.join(UPLOAD_FOLDER, f"{task_id}.jpg")
        if len(temp_image_paths) == 1:
            os.rename(temp_image_paths[0], stitched_image_path)
            temp_image_paths = []
        else:
            _stitch_images_vertically(temp_image_paths, stitched_image_path)
            for path in temp_image_paths:
                if os.path.exists(path):
                    os.remove(path)
            temp_image_paths = []

    except Exception as e:
        for path in temp_image_paths:
            if os.path.exists(path):
                os.remove(path)
        return jsonify(success=False, message=f"图片处理失败: {str(e)}"), 400

    task = {
        "task_id": task_id,
        "status": "pending",
        "model": data.get("model"),
        "level": data.get("level", 3),
        "image_count": len(file_urls) + len(images_base64),
        "created_at": time.time()
    }
    _save_task(task_id, task)

    threading.Thread(
        target=_audit_worker,
        args=(task_id, stitched_image_path, task["model"], task["level"]),
        daemon=True
    ).start()

    return jsonify(success=True, data={
        "taskId": task_id,
        "status": "pending"
    })


def api_get_task(task_id):
    task = _load_task(task_id)
    if not task:
        return jsonify(success=False, message="任务不存在或已过期"), 404

    if task["status"] == "completed":
        return jsonify(success=True, data={
            "status": "completed",
            "result": task["result"]
        })

    if task["status"] == "failed":
        return jsonify(success=False, message=task.get("error"))

    return jsonify(success=True, data={
        "status": task["status"]
    })
