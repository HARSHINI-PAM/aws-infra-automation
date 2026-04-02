#!/bin/bash
 
# ==============================
# CONFIGURATION
# ==============================
 
REGION="ap-south-1"
INSTANCE_TYPE="t2.micro"
KEY_NAME="your-key-name"
SECURITY_GROUP_ID="sg-xxxxxxxx"
 
echo "🔍 Fetching latest Amazon Linux AMI..."
 
# ==============================
# DYNAMIC AMAZON LINUX AMI
# ==============================
 
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=state,Values=available" \
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
# 2️⃣ FILE MANAGER SERVER
# ==============================
 
echo "🚀 Creating File Manager Server..."
 
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
 
echo "🚀 Creating Clock Server..."
 
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
<title>Global Clock</title>
<style>
body { background:#0f172a; color:white; text-align:center; font-family:Arial; }
.container { display:flex; justify-content:space-around; margin-top:50px; }
.clock { background:#1e293b; padding:30px; border-radius:12px; }
.time { font-size:30px; }
</style>
</head>
<body>
 
<h1>🌍 Global Time Dashboard</h1>
 
<div class="container">
<div class="clock">
<h2>GMT</h2>
<div class="time" id="gmt"></div>
</div>
 
<div class="clock">
<h2>IST</h2>
<div class="time" id="ist"></div>
</div>
 
<div class="clock">
<h2>PST</h2>
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
 
# ==============================
# WAIT FOR INSTANCES
# ==============================
 
echo "⏳ Waiting for instances..."
 
aws ec2 wait instance-running \
    --instance-ids $ID1 $ID2 $ID3 \
    --region $REGION
 
sleep 20
 
# ==============================
# FETCH PUBLIC IPS
# ==============================
 
IPS=$(aws ec2 describe-instances \
    --instance-ids $ID1 $ID2 $ID3 \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --region $REGION \
    --output text)
 
IPS_ARRAY=($IPS)
 
WEB_IP=${IPS_ARRAY[0]}
FILE_IP=${IPS_ARRAY[1]}
CLOCK_IP=${IPS_ARRAY[2]}
 
# ==============================
# OUTPUT
# ==============================
 
echo "======================================"
echo "🎉 Linux Servers Ready!"
echo "======================================"
 
echo "🌐 Web Server      → http://$WEB_IP"
echo "📁 File Manager    → http://$FILE_IP"
echo "🕒 Clock Dashboard → http://$CLOCK_IP"
