#!/bin/bash

AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Selected Linux AMI: $AMI_ID"
 
# Safety check
if [ -z "$AMI_ID" ]; then
  echo "❌ AMI_ID is empty. Exiting..."
  exit 1
fi 

echo "🚀 Creating Linux Servers..."
 
# ========================
# 1️⃣ Project Dashboard
# ========================
ID1=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-Dashboard}]" \
--user-data '#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl enable nginx
systemctl start nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>🚀 DevOps Automation Project</h1>
<p>Automated AWS infrastructure using scripts</p>
<p>Linux + Windows + DevOps Tools</p>
EOF
')
 
# ========================
# 2️⃣ DevOps Server
# ========================
ID2=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-DevOps}]" \
--user-data '#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
yum install docker -y
 
systemctl enable nginx docker
systemctl start nginx docker
 
docker run -d -p 8080:80 nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>⚙️ DevOps Server</h1>
<p>Nginx + Docker Running</p>
<p>Docker App: :8080</p>
EOF
')
 
# ========================
# 3️⃣ File Manager
# ========================
ID3=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-FileManager}]" \
--user-data '#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx
 
mkdir -p /home/ec2-user/project
echo "This project automates infrastructure deployment using AWS CLI and DevOps tools." > /home/ec2-user/project/info.txt
 
TREE=$(ls -R /home/ec2-user)
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>📂 File Manager</h1>
<pre>$TREE</pre>
EOF
')
 
sleep 60
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 $ID3 \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)
 
IPS_ARRAY=($IPS)
 
echo "🐧 Linux Ready:"
echo "Dashboard → http://${IPS_ARRAY[0]}"
echo "DevOps    → http://${IPS_ARRAY[1]}"
echo "FileMgr   → http://${IPS_ARRAY[2]}"
echo "Docker    → http://${IPS_ARRAY[1]}:8080"
