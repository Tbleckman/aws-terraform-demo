#!/bin/bash
dnf update -y
dnf install -y nginx
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
  </main>

  <footer>
    © 2026 Thomas Bleckman | AWS Terraform Demo
  </footer>
</body>
</html>
EOF

sed -i "s/HOSTNAME_PLACEHOLDER/$(hostname)/g" /usr/share/nginx/html/index.html