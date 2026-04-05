#!/bin/bash
 
echo "🚀 Creating Linux Servers..."
 
# ==============================
# DYNAMIC AMI
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo "❌ Failed to fetch Linux AMI"
  exit 1
fi
 
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
systemctl enable nginx
systemctl start nginx
sleep 20
 
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>DevOps Dashboard</title>
<style>
body {font-family: Arial; background: linear-gradient(to right,#1f4037,#99f2c8); color:white; text-align:center;}
.container {margin-top:100px;}
.card {background: rgba(0,0,0,0.6); padding:30px; border-radius:10px;}
</style>
</head>
<body>
<div class="container">
<div class="card">
<h1>🚀 AWS DevOps Automation Project</h1>
<p>This project demonstrates automated infrastructure provisioning using AWS EC2 and GitHub Actions.</p>
<p>Multiple servers are created dynamically, each performing a dedicated role.</p>
<p>This approach reduces manual effort, ensures consistency, and enables faster deployments.</p>
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
yum install nginx docker -y
systemctl enable nginx
systemctl start nginx
systemctl enable docker
systemctl start docker
 
docker run -d -p 8080:80 nginx
 
sleep 20
 
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>DevOps Server</title>
<style>
body {font-family:Arial;background:#0f2027;color:white;text-align:center;}
.card {margin-top:100px;}
</style>
</head>
<body>
 
<div class="card">
<h1>⚙ DevOps Server</h1>
<p>This server demonstrates containerized deployment using Docker and Nginx.</p>
<p>A Docker container is running a web application on port 8080.</p>
<p>This reflects real-world DevOps practices such as containerization and service automation.</p>
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
systemctl enable nginx
systemctl start nginx
 
mkdir -p /home/ec2-user/project
echo "This project showcases automated infrastructure provisioning using DevOps practices." > /home/ec2-user/project/info.txt
 
TREE=$(ls -R /home/ec2-user/project)
 
sleep 20
 
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>File Manager</title>
<style>
body {background:#232526;color:white;font-family:Arial;text-align:center;}
pre {background:black;padding:10px;}
</style>
</head>
<body>
 
<h1>📁 File Manager Server</h1>
<p>This server demonstrates automated file creation and management.</p>
<p>Such automation is useful in real-world applications for log handling, backups, and configuration management.</p>
 
<pre>$TREE</pre>
 
</body>
</html>
EOF
'
 
echo "⏳ Linux servers launched"
