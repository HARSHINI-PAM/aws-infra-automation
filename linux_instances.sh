#!/bin/bash
set -e
 
echo "🐧 Starting Linux Deployment..."
echo "Using REGION: $REGION"
echo "Using KEY: $KEY_NAME"
echo "Using SG: $SECURITY_GROUP_ID"
 
# ==============================
# DYNAMIC AMAZON LINUX AMI
# ==============================
 
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region $REGION \
  --output text)
 
echo "✅ Latest AMI: $AMI_ID"
 
# ==============================
# 1️⃣ WEB SERVER
# ==============================
 
echo "🚀 Creating Web Server..."
 
ID1=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --associate-public-ip-address \
  --region $REGION \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-Web}]" \
  --user-data '#!/bin/bash
yum update -y
yum install nginx -y
systemctl start nginx
systemctl enable nginx
echo "<h1>🚀 Linux Web Server Running</h1>" > /usr/share/nginx/html/index.html
' \
  --query "Instances[0].InstanceId" \
  --output text)
 
# ==============================
# 2️⃣ FILE MANAGER
# ==============================
 
echo "📁 Creating File Manager..."
 
ID2=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --associate-public-ip-address \
  --region $REGION \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-File}]" \
  --user-data '#!/bin/bash
yum update -y
yum install nginx -y
systemctl start nginx
systemctl enable nginx
 
mkdir -p /home/ec2-user/projects/demo
echo "Hello DevOps 🚀" > /home/ec2-user/projects/demo/file.txt
 
TREE=$(ls -R /home/ec2-user/projects)
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>📁 File Manager</h1>
<pre>$TREE</pre>
<meta http-equiv="refresh" content="5">
EOF
' \
  --query "Instances[0].InstanceId" \
  --output text)
 
# ==============================
# 3️⃣ CLOCK SERVER
# ==============================
 
echo "🕒 Creating Clock Server..."
 
ID3=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --associate-public-ip-address \
  --region $REGION \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-Clock}]" \
  --user-data '#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Clock</title>
</head>
<body>
<h1>🕒 Clock Server Running</h1>
<script>
setInterval(() => {
  document.body.innerHTML = "<h1>" + new Date().toLocaleString() + "</h1>";
}, 1000);
</script>
</body>
</html>
EOF
' \
  --query "Instances[0].InstanceId" \
  --output text)
 
# ==============================
# WAIT + IPS
# ==============================
 
aws ec2 wait instance-running --instance-ids $ID1 $ID2 $ID3 --region $REGION
 
IPS=$(aws ec2 describe-instances \
  --instance-ids $ID1 $ID2 $ID3 \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --region $REGION \
  --output text)
 
IPS_ARRAY=($IPS)
 
echo "================================="
echo "🎉 Linux Servers Ready!"
echo "================================="
 
echo "🌐 Web: http://${IPS_ARRAY[0]}"
echo "📁 File: http://${IPS_ARRAY[1]}"
echo "🕒 Clock: http://${IPS_ARRAY[2]}"
