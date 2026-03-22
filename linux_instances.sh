#!/bin/bash
 
AMI_ID="ami-037688ecd92e8611e"
 
echo "🚀 Creating Linux Servers..."
 
# ========================
# 1️⃣ DevOps Web Server
# ========================
ID1=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-DevOps-Web}]" \
--user-data '#!/bin/bash
yum update -y
yum install nginx docker -y
 
systemctl start nginx
systemctl enable nginx
systemctl start docker
systemctl enable docker
 
docker run -d -p 8080:80 --name devops-nginx nginx
 
TOP=$(top -bn1 | grep "Cpu")
MEM=$(free -h | grep Mem)
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>🚀 DevOps Server</h1>
<pre>$TOP</pre>
<pre>$MEM</pre>
<pre>$(docker ps)</pre>
<meta http-equiv="refresh" content="5">
EOF
' \
--query "Instances[0].InstanceId" \
--output text)
 
# ========================
# 2️⃣ File Manager
# ========================
ID2=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-File-Manager}]" \
--user-data '#!/bin/bash
yum install nginx -y
systemctl start nginx
systemctl enable nginx
 
mkdir -p /home/ec2-user/projects/demo
echo "Hello DevOps" > /home/ec2-user/projects/demo/file.txt
 
TREE=$(ls -R /home/ec2-user/projects)
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>📂 File Manager</h1>
<pre>$TREE</pre>
<meta http-equiv="refresh" content="5">
EOF
' \
--query "Instances[0].InstanceId" \
--output text)
 
# ========================
# 3️⃣ Database Server
# ========================
ID3=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-Database}]" \
--user-data '#!/bin/bash
yum update -y
yum install mysql-server nginx -y
 
systemctl start mysqld
systemctl enable mysqld
systemctl start nginx
 
STATUS=$(systemctl is-active mysqld)
 
cat <<EOF > /usr/share/nginx/html/index.html
<h1>🗄️ Database Server</h1>
<p>Status: $STATUS</p>
<meta http-equiv="refresh" content="5">
EOF
' \
--query "Instances[0].InstanceId" \
--output text)
 
echo "⏳ Waiting for Linux instances..."
sleep 50
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 $ID3 \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)
 
IPS_ARRAY=($IPS)
 
export LINUX_WEB_IP=${IPS_ARRAY[0]}
export FILE_MANAGER_IP=${IPS_ARRAY[1]}
export DATABASE_IP=${IPS_ARRAY[2]}
 
echo "🐧 Linux Servers Ready:"
echo "Web → http://${LINUX_WEB_IP}"
echo "File → http://${FILE_MANAGER_IP}"
echo "DB → http://${DATABASE_IP}"
