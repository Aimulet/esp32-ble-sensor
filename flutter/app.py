from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from flask_cors import CORS
from datetime import datetime
import requests

app = Flask(__name__)
CORS(app)

# MongoDB配置
app.config["MONGO_URI"] = "mongodb://localhost:27017/aimulet_db"
mongo = PyMongo(app)

# 短信服务配置（示例使用阿里云）
SMS_API_KEY = "your_api_key"
SMS_SECRET = "your_secret"

@app.route("/api/register", methods=["POST"])
def register():
    data = request.json
    phone = data.get("phone")
    password = data.get("password")
    verify_code = data.get("verify_code")
    
    # 验证短信验证码
    if not verify_sms_code(phone, verify_code):
        return jsonify({"error": "验证码错误"}), 400
    
    # 检查用户是否已存在
    if mongo.db.users.find_one({"phone": phone}):
        return jsonify({"error": "用户已存在"}), 400
    
    # 创建新用户
    user = {
        "phone": phone,
        "password": password,  # 实际应用中需要加密
        "created_at": datetime.utcnow()
    }
    mongo.db.users.insert_one(user)
    
    return jsonify({"message": "注册成功"}), 201

@app.route("/api/send_code", methods=["POST"])
def send_verification_code():
    phone = request.json.get("phone")
    code = generate_verification_code()
    
    # 发送短信验证码
    send_sms(phone, code)
    
    # 保存验证码到数据库（设置过期时间）
    mongo.db.verification_codes.insert_one({
        "phone": phone,
        "code": code,
        "created_at": datetime.utcnow()
    })
    
    return jsonify({"message": "验证码已发送"}), 200

@app.route("/api/sensor_data", methods=["POST"])
def save_sensor_data():
    data = request.json
    user_id = data.get("user_id")
    sensor_data = data.get("sensor_data")
    
    record = {
        "user_id": user_id,
        "sensor_data": sensor_data,
        "timestamp": datetime.utcnow()
    }
    mongo.db.sensor_data.insert_one(record)
    
    return jsonify({"message": "数据保存成功"}), 201

if __name__ == "__main__":
    app.run(debug=True) 