#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y docker amazon-cloudwatch-agent amazon-ssm-agent

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

systemctl enable docker
systemctl start docker

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 563224522493.dkr.ecr.us-east-1.amazonaws.com

docker run -d \
  --name portfolio-app \
  --restart always \
  -p 80:5000 \
  563224522493.dkr.ecr.us-east-1.amazonaws.com/portfolio-app:latest