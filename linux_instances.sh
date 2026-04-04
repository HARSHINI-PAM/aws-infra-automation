#!/bin/bash
 
echo "🚀 Creating Linux Servers..."
 
# ==============================
# DYNAMIC AMI
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Linux AMI: $AMI_ID"
 
# ==============================
# 1️⃣ DASHBOARD SERVER
# ==============================
aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Linux-Dashboard}]' \
--user-data '#!/bin/bash
yum install nginx -y
systemctl start nginx
systemctl enable nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head>
<title>DevOps Dashboard</title>
<style>
body {font-family: Arial; background: linear-gradient(to right,#1f4037,#99f2c8); color:white; text-align:center;}
.container {margin-top:100px;}
.card {background: rgba(0,0,0,0.5); padding:20px; border-radius:10px;}
</style>
</head>
<body>
<div class="container">
<div class="card">
<h1>🚀 AWS DevOps Automation Project</h1>
<p>This project demonstrates automated infrastructure provisioning using AWS EC2, GitHub Actions, and Bash scripting.</p>
<p>It dynamically creates multiple servers with different roles such as dashboard, DevOps tools, and file management.</p>
<p>Fully automated CI/CD pipeline ensures quick deployment and cleanup.</p>
</div>
</div>
</body>
</html>
EOF
'
 
# ==============================
# 2️⃣ DEVOPS SERVER
# ==============================
aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Linux-DevOps}]' \
--user-data '#!/bin/bash
yum install docker nginx -y
systemctl start docker
systemctl enable docker
systemctl start nginx
 
docker run -d -p 8080:80 nginx
 
CPU=$(top -bn1 | grep "Cpu")
MEM=$(free -h | grep Mem)
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head>
<title>DevOps Server</title>
<style>
body {font-family:Arial; background:#0f2027; color:white; text-align:center;}
.box {margin-top:50px;}
</style>
</head>
<body>
<div class="box">
<h1>⚙ DevOps Server</h1>
<p>This server runs Docker & Nginx to simulate containerized deployment.</p>
<h3>📊 System Stats</h3>
<p>$CPU</p>
<p>$MEM</p>
<p>Docker Container running on port 8080</p>
</div>
</body>
</html>
EOF
'
 
# ==============================
# 3️⃣ FILE MANAGER
# ==============================
aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Linux-FileManager}]' \
--user-data '#!/bin/bash
yum install nginx -y
systemctl start nginx
 
mkdir -p /home/ec2-user/project
echo "This project automates infrastructure provisioning using DevOps practices." > /home/ec2-user/project/info.txt
 
TREE=$(ls -R /home/ec2-user/project)
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head>
<title>File Manager</title>
<style>
body {background:#232526; color:white; font-family:Arial;}
pre {background:black; padding:10px;}
</style>
</head>
<body>
<h1>📁 File Manager</h1>
<p>This server demonstrates file creation and management automation.</p>
<pre>$TREE</pre>
</body>
</html>
EOF
'
 
echo "⏳ Linux servers launched"
