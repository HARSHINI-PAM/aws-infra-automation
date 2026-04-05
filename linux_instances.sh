#!/bin/bash
 
echo "🚀 Creating Linux Servers..."
 
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "Using AMI: $AMI_ID"
 
# ================= DASHBOARD =================
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
sleep 30
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head>
<style>
body {background: linear-gradient(to right,#1f4037,#99f2c8);color:white;text-align:center;font-family:Arial;}
</style>
</head>
<body>
<h1>🚀 DevOps Automation Dashboard</h1>
<p>This project automates AWS infrastructure creation using scripts and CI/CD.</p>
<p>Multiple servers are created dynamically with different roles.</p>
</body>
</html>
EOF
'
 
# ================= DEVOPS =================
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
systemctl start nginx
systemctl enable nginx
systemctl start docker
 
docker run -d -p 8080:80 nginx
sleep 30
 
echo "<h1>⚙ DevOps Server (Docker + Nginx)</h1>" > /usr/share/nginx/html/index.html
'
 
# ================= FILE MANAGER =================
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
systemctl enable nginx
 
mkdir -p /home/ec2-user/project
echo "DevOps Automation Project File Manager" > /home/ec2-user/project/info.txt
 
sleep 30
 
TREE=$(ls -R /home/ec2-user/project)
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<body style="background:black;color:white;text-align:center;">
<h1>📁 File Manager</h1>
<pre>$TREE</pre>
</body>
</html>
EOF
'
 
echo "✅ Linux servers created"
