#!/bin/bash
set -euo pipefail
 
echo "🚀 Creating Linux Servers..." >&2
 
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "Images | sort_by(@,&CreationDate)[-1].ImageId" \
  --output text)
 
[[ "$AMI_ID" =~ ^ami- ]] || { echo "❌ AMI fetch failed" >&2; exit 1; }
 
echo "Using AMI: $AMI_ID" >&2
 
launch_instance () {
  NAME=$1
  USERDATA=$2
 
  TMP_FILE=$(mktemp)
  echo "$USERDATA" > "$TMP_FILE"
 
  ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --associate-public-ip-address \
    --region "$REGION" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --user-data file://"$TMP_FILE" \
    --query 'Instances[0].InstanceId' \
    --output text)
 
  rm -f "$TMP_FILE"
 
  [[ "$ID" =~ ^i- ]] || { echo "❌ Instance launch failed" >&2; exit 1; }
 
  echo "$ID"
}
 
IDS=""
 
# ================= DASHBOARD =================
IDS+=" $(launch_instance "Linux-Dashboard" '#!/bin/bash
 
exec > /var/log/user-data.log 2>&1
 
echo "Starting Dashboard setup..."
 
for i in {1..5}; do yum update -y && break || sleep 5; done
 
# FIX: Proper nginx install
for i in {1..5}; do amazon-linux-extras install -y nginx1 && break || sleep 5; done
 
systemctl enable nginx
systemctl restart nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<style>
body{background:#0f172a;color:#38bdf8;text-align:center;font-family:Arial}
.card{background:#020617;padding:20px;margin:20px;border-radius:10px}
</style>
<h1>🚀 DevOps Dashboard</h1>
<div class="card">
<p>Uptime: \$(uptime)</p>
<pre>\$(free -h)</pre>
</div>
</html>
EOF
')"
 
# ================= DEVOPS =================
IDS+=" $(launch_instance "Linux-DevOps" '#!/bin/bash
 
exec > /var/log/user-data.log 2>&1
 
echo "Starting DevOps setup..."
 
for i in {1..5}; do yum update -y && break || sleep 5; done
 
# FIXED INSTALLATION
for i in {1..5}; do amazon-linux-extras install -y nginx1 && break || sleep 5; done
for i in {1..5}; do yum install -y docker && break || sleep 5; done
 
systemctl enable nginx docker
systemctl restart nginx docker
 
# Ensure nginx is running
systemctl is-active nginx || systemctl restart nginx
 
# Run docker container
docker rm -f nginx || true
docker run -d --restart always -p 8080:80 nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<body style="background:#111;color:#0f0;text-align:center;">
<h1>⚙ DevOps Server</h1>
<p>Nginx (port 80) + Docker (port 8080)</p>
</body>
</html>
EOF
')"
 
# ================= FILE MANAGER =================
IDS+=" $(launch_instance "Linux-File-Manager" '#!/bin/bash
 
exec > /var/log/user-data.log 2>&1
 
echo "Starting File Manager setup..."
 
for i in {1..5}; do yum update -y && break || sleep 5; done
 
# FIX nginx install
for i in {1..5}; do amazon-linux-extras install -y nginx1 && break || sleep 5; done
 
systemctl enable nginx
systemctl restart nginx
 
mkdir -p /home/ec2-user/project
echo "DevOps File Manager" > /home/ec2-user/project/info.txt
 
FILES=\$(ls -lah /home/ec2-user/project)
 
cat <<EOF > /usr/share/nginx/html/index.html
<html>
<style>
body{background:black;color:white;text-align:center;font-family:Arial}
pre{background:#222;padding:10px}
</style>
<h1>📁 File Manager</h1>
<pre>\$FILES</pre>
</html>
EOF
')"
 
echo "✅ Linux servers created" >&2
echo $IDS
 
