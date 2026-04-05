#!/bin/bash
set -euo pipefail
 
echo "🚀 Creating Linux Servers..."
 
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
  --query "Images | sort_by(@,&CreationDate)[-1].ImageId" \
  --output text)
 
[[ "$AMI_ID" =~ ^ami- ]] || { echo "❌ AMI fetch failed"; exit 1; }
 
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
 
  [[ "$ID" =~ ^i- ]] || { echo "❌ Instance launch failed"; exit 1; }
 
  echo "$ID"
}
 
IDS=""
 
# DASHBOARD
IDS+=" $(launch_instance "Linux-Dashboard" '#!/bin/bash
yum update -y
yum install -y nginx
 
systemctl enable nginx
systemctl start nginx
 
until systemctl is-active nginx; do sleep 2; done
 
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
 
# DEVOPS
IDS+=" $(launch_instance "Linux-DevOps" '#!/bin/bash
yum update -y
yum install -y nginx docker
 
systemctl enable nginx docker
systemctl start nginx docker
 
until systemctl is-active docker; do sleep 2; done
 
docker rm -f nginx || true
docker run -d --restart always -p 8080:80 nginx
 
echo "<h1>DevOps Server Running (Docker on 8080)</h1>" > /usr/share/nginx/html/index.html
')"
 
# FILE MANAGER
IDS+=" $(launch_instance "Linux-File-Manager" '#!/bin/bash
yum update -y
yum install -y nginx
 
systemctl enable nginx
systemctl start nginx
 
mkdir -p /home/ec2-user/project
echo "DevOps File Manager" > /home/ec2-user/project/info.txt
 
until systemctl is-active nginx; do sleep 2; done
 
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
 
echo $IDS
 
