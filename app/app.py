from flask import Flask, request, jsonify, render_template
import boto3
import uuid
import datetime
import socket

app = Flask(__name__)

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamodb.Table("user-handles")

@app.route("/", methods=["GET"])
def home():
    return render_template("index.html", hostname=socket.gethostname())

@app.route("/api/contact", methods=["POST"])
def contact():
    data = request.get_json() or {}

    item = {
        "UserId": str(uuid.uuid4()),
        "name": data.get("name", ""),
        "linkedin": data.get("linkedin", ""),
        "message": data.get("message", ""),
        "createdAt": datetime.datetime.utcnow().isoformat()
    }
    table.put_item(Item=item)

    return jsonify({"message": "Contact saved successfully"}), 200

@app.route("/health", methods=["GET"])
def health():
    return "OK", 200