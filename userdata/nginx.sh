#!/bin/bash
dnf update -y
dnf install -y nginx python3 python3-pip

pip3 install flask boto3

systemctl stop ecs || true
systemctl disable ecs || true
systemctl enable nginx
systemctl start nginx
#echo "<h1> Hello from $(hostname) <h1>" > /usr/share/nginx/html/index.html 

cat <<'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Thomas Bleckman | Cloud Portfolio</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: #f4f7fb;
      color: #1f2937;
    }

    header {
      background: #0f172a;
      color: white;
      padding: 60px 20px;
      text-align: center;
    }

    header h1 {
      font-size: 2.5rem;
      margin-bottom: 10px;
    }

    header p {
      font-size: 1.1rem;
      color: #cbd5e1;
    }

    main {
      max-width: 900px;
      margin: 40px auto;
      padding: 0 20px;
    }

    .card {
      background: white;
      padding: 25px;
      margin-bottom: 20px;
      border-radius: 12px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.08);
    }

    h2 {
      color: #0f172a;
    }

    .tech {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }

    .tech span {
      background: #e0f2fe;
      color: #0369a1;
      padding: 8px 12px;
      border-radius: 999px;
      font-size: 0.9rem;
    }

    footer {
      text-align: center;
      padding: 25px;
      color: #64748b;
    }
  </style>
</head>
<body>
  <header>
    <h1>Thomas Bleckman</h1>
    <p>Cloud / Infrastructure / Terraform Portfolio Project</p>
  </header>

  <main>
    <section class="card">
      <h2>About This Project</h2>
      <p>
        This website is being served from an EC2 instance provisioned with Terraform.
        Traffic is routed through an Application Load Balancer as part of a multi-tier AWS architecture.
      </p>
    </section>

    <section class="card">
      <h2>Architecture</h2>
      <p>
        Current stack includes a custom VPC, public subnets, private application instances,
        security groups, an ALB, Route 53, ACM, and Nginx running on EC2.
      </p>
    </section>

    <section class="card">
      <h2>Technologies Used</h2>
      <div class="tech">
        <span>AWS</span>
        <span>Terraform</span>
        <span>EC2</span>
        <span>ALB</span>
        <span>Route 53</span>
        <span>ACM</span>
        <span>Nginx</span>
        <span>Linux</span>
      </div>
    </section>

    <section class="card">
      <h2>Instance Info</h2>
      <p>This page is being served from instance: <strong>HOSTNAME_PLACEHOLDER</strong></p>
    </section>

    <section class="card">
  <h2>Get In Touch</h2>
  <p>Leave your name, LinkedIn, and a message and I'll reach out.</p>
  <div style="display:flex; flex-direction:column; gap:12px; max-width:500px;">
    <input  type="text" id="name"     placeholder="Your Name"    style="padding:10px; border-radius:8px; border:1px solid #cbd5e1; font-size:1rem;" />
    <input  type="text" id="linkedin" placeholder="LinkedIn URL" style="padding:10px; border-radius:8px; border:1px solid #cbd5e1; font-size:1rem;" />
    <textarea           id="message"  placeholder="Message"      style="padding:10px; border-radius:8px; border:1px solid #cbd5e1; font-size:1rem; height:100px;"></textarea>
    <button id="submitBtn" onclick="submitContact()" style="padding:10px 20px; background:#0369a1; color:white; border:none; border-radius:8px; font-size:1rem; cursor:pointer;">
      Submit
    </button>
    <p id="formStatus" style="margin:0; font-size:0.95rem;"></p>
  </div>
</section>

<script>
  async function submitContact() {
    const name     = document.getElementById("name").value.trim();
    const linkedin = document.getElementById("linkedin").value.trim();
    const message  = document.getElementById("message").value.trim();
    const status   = document.getElementById("formStatus");

    if (!name || !linkedin || !message) {
      status.textContent = "Please fill out all fields.";
      status.style.color = "#b45309";
      return;
    }

    document.getElementById("submitBtn").disabled = true;
    status.textContent = "Submitting...";
    status.style.color = "#64748b";

    try {
      const res = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, linkedin, message })
      });

      if (res.ok) {
        status.textContent = "Submitted! I'll be in touch.";
        status.style.color = "#15803d";
        document.getElementById("name").value = "";
        document.getElementById("linkedin").value = "";
        document.getElementById("message").value = "";
      } else {
        status.textContent = "Server error. Please try again.";
        status.style.color = "#b91c1c";
      }
    } catch (err) {
      status.textContent = "Network error. Please try again.";
      status.style.color = "#b91c1c";
    }

    document.getElementById("submitBtn").disabled = false;
  }
</script>
  </main>

  <footer>
    © 2026 Thomas Bleckman | AWS Terraform Demo
  </footer>
</body>
</html>
EOF

sed -i "s/HOSTNAME_PLACEHOLDER/$(hostname)/g" /usr/share/nginx/html/index.html

cat > /home/ec2-user/app.py << 'EOF'
from flask import Flask, request, jsonify
import boto3
import uuid
import datetime

app = Flask(__name__)

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamodb.Table("user-handles")

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

cat > /etc/systemd/system/flask.service << 'EOF'
[Unit]
Description=Flask Backend
After=network.target

[Service]
User=ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask
systemctl start flask


# Configure nginx to proxy /api/* to Flask
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
    }
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
EOF

systemctl restart nginx