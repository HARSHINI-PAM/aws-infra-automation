#!/bin/bash
 
# ==============================
# CONFIGURATION
# ==============================
 
REGION="ap-south-1"
INSTANCE_TYPE="t2.micro"
KEY_NAME="your-key-name"
SECURITY_GROUP_ID="sg-xxxxxxxx"
 
echo "🔍 Fetching latest Windows AMI..."
 
# ==============================
# DYNAMIC WINDOWS AMI
# ==============================
 
WINDOWS_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=Windows_Server-2019-English-Full-Base-*" \
              "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --region $REGION \
    --output text)
 
echo "✅ Latest Windows AMI: $WINDOWS_AMI"
 
# ==============================
# CREATE MONITOR SERVER
# ==============================
 
echo "🚀 Creating Windows Monitor Server..."
 
ID1=$(aws ec2 run-instances \
    --image-id $WINDOWS_AMI \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --associate-public-ip-address \
    --region $REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Windows-Monitor}]" \
    --user-data '<powershell>
Install-WindowsFeature Web-Server
 
$cpu = Get-Counter "\Processor(_Total)\% Processor Time"
$hostname = hostname
 
$html = "<meta http-equiv=\"refresh\" content=\"5\"><h1>🖥️ Monitor Server</h1><p>Host: $hostname</p><p>CPU Usage: $($cpu.CounterSamples[0].CookedValue)%</p>"
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
    --query "Instances[0].InstanceId" \
    --output text)
 
echo "✅ Monitor Instance ID: $ID1"
 
# ==============================
# CREATE FRONTEND SERVER
# ==============================
 
echo "🚀 Creating Windows Frontend Server..."
 
ID2=$(aws ec2 run-instances \
    --image-id $WINDOWS_AMI \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --associate-public-ip-address \
    --region $REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Windows-Frontend}]" \
    --user-data '<powershell>
Install-WindowsFeature Web-Server
 
$html = @"
<!DOCTYPE html>
<html>
<body style="background:#0f172a;color:white;text-align:center;font-family:Arial">
<h1>🚀 DevOps Dashboard</h1>
<p>Frontend is running successfully</p>
</body>
</html>
"@
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
    --query "Instances[0].InstanceId" \
    --output text)
 
echo "✅ Frontend Instance ID: $ID2"
 
# ==============================
# WAIT FOR INSTANCES
# ==============================
 
echo "⏳ Waiting for instances to be running..."
 
aws ec2 wait instance-running \
    --instance-ids $ID1 $ID2 \
    --region $REGION
 
echo "⏳ Waiting for system checks..."
sleep 40
 
# ==============================
# FETCH PUBLIC IPS
# ==============================
 
IPS=$(aws ec2 describe-instances \
    --instance-ids $ID1 $ID2 \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --region $REGION \
    --output text)
 
IPS_ARRAY=($IPS)
 
MONITOR_IP=${IPS_ARRAY[0]}
FRONTEND_IP=${IPS_ARRAY[1]}
 
# ==============================
# FINAL OUTPUT
# ==============================
 
echo "======================================"
echo "🎉 Windows Servers Deployed Successfully!"
echo "======================================"
 
echo "🖥️ Monitor   → http://$MONITOR_IP"
echo "🌐 Frontend  → http://$FRONTEND_IP"
 
echo "💡 Note:"
echo "- If not loading immediately, wait 1–2 minutes"
echo "- Ensure Security Group allows HTTP (port 80)"
