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
# 3️⃣ Clock Server (Replaces Database)
# ========================
ID3=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Linux-Clock-Server}]" \
--user-data '#!/bin/bash
yum update -y
 
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx
 
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Global Clock Dashboard</title>
<style>
body {
  background: #0f172a;
  color: white;
  text-align: center;
  font-family: Arial;
}
.container {
  display: flex;
  justify-content: space-around;
  margin-top: 50px;
}
.clock {
  background: #1e293b;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 0 20px rgba(0,0,0,0.5);
}
h2 { margin-bottom: 20px; }
.time { font-size: 30px; }
</style>
</head>
 
<body>
 
<h1>🌍 Global Time Dashboard</h1>
 
<div class="container">
  <div class="clock">
    <h2>🇬🇧 GMT</h2>
    <div class="time" id="gmt"></div>
  </div>
 
  <div class="clock">
    <h2>🇮🇳 IST</h2>
    <div class="time" id="ist"></div>
  </div>
 
  <div class="clock">
    <h2>🇺🇸 PST</h2>
    <div class="time" id="pst"></div>
  </div>
</div>
 
<script>
function updateTime() {
  const now = new Date();
 
  document.getElementById("gmt").innerHTML =
    now.toLocaleTimeString("en-GB", { timeZone: "UTC" });
 
  document.getElementById("ist").innerHTML =
    now.toLocaleTimeString("en-IN", { timeZone: "Asia/Kolkata" });
 
  document.getElementById("pst").innerHTML =
    now.toLocaleTimeString("en-US", { timeZone: "America/Los_Angeles" });
}
 
setInterval(updateTime, 1000);
updateTime();
</script>
 
</body>
</html>
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
export CLOCK_IP=${IPS_ARRAY[2]}
 
echo "🐧 Linux Servers Ready:"
echo "Web → http://${LINUX_WEB_IP}"
echo "File → http://${FILE_MANAGER_IP}"
echo "FRONTEND → http://${FRONTEND_IP}"
