#!/bin/bash
dnf update -y
dnf install -y nginx
systemc1 enable nginx
systemc1 start nginx
echo "Hello from $(hostname)" > usr/share/nginx/html/index.html 
