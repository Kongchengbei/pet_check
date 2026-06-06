from flask import Flask
from config import HOST, PORT, DEBUG
from Function_Management import (api_index,api_health,api_upload_file,api_audit_image,api_get_task,api_serve_upload)
from flask_cors import CORS
import logging

logging.basicConfig(level=logging.INFO)
app = Flask(__name__)
CORS(app)
app.add_url_rule("/", view_func=api_index, methods=["GET"])
app.add_url_rule("/api/health", view_func=api_health, methods=["GET"])
app.add_url_rule("/api/upload", view_func=api_upload_file, methods=["POST"])
app.add_url_rule("/api/audit", view_func=api_audit_image, methods=["POST"])
app.add_url_rule("/api/task/<task_id>", view_func=api_get_task, methods=["GET"])
app.add_url_rule("/uploads/<filename>",view_func=api_serve_upload,methods=["GET"])

if __name__ == "__main__":
    app.run(host=HOST,port=PORT,debug=DEBUG)
    print("🚀 Flask 服务启动")
    print(f"HOST={HOST}")
    print(f"PORT={PORT}")
    print(f"DEBUG={DEBUG}")