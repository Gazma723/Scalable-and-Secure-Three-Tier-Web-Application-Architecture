#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello, World! 🌍💻 This is a new project tested by AMULEYA 🚀⚙️ from $(hostname -f)" > /var/www/html/index.html
