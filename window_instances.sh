#!/bin/bash
set -e
 
echo "🪟 Starting Windows Deployment..."
echo "Using REGION: $REGION"
echo "Using KEY: $KEY_NAME"
echo "Using SG: $SECURITY_GROUP_ID"
 
# ==============================
# DYNAMIC WINDOWS AMI
# ==============================
 
WINDOWS_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2019-English-Full-Base-*" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --region $REGION \
  --output text)
 
echo "✅ Windows AMI: $WINDOWS_AMI"
 
# ==============================
# 1️⃣ MONITOR SERVER
# ==============================
 
echo "🚀 Creating Monitor Server..."
 
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
Start-Service W3SVC
 
$cpu = Get-Counter "\Processor(_Total)\% Processor Time"
$hostname = hostname
 
$html = "<meta http-equiv=\"refresh\" content=\"5\"><h1>Monitor</h1><p>$hostname</p><p>CPU: $($cpu.CounterSamples[0].CookedValue)%</p>"
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
  --query "Instances[0].InstanceId" \
  --output text)
 
# ==============================
# 2️⃣ FRONTEND SERVER
# ==============================
 
echo "🚀 Creating Frontend Server..."
 
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
Start-Service W3SVC
 
$html = @"
<!DOCTYPE html>
<html>
<body style="background:#0f172a;color:white;text-align:center;font-family:Arial">
<h1>🚀 DevOps Dashboard</h1>
<p>Windows Frontend Running</p>
</body>
</html>
"@
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
  --query "Instances[0].InstanceId" \
  --output text)
 
# ==============================
# WAIT + IPS
# ==============================
 
aws ec2 wait instance-running --instance-ids $ID1 $ID2 --region $REGION
 
IPS=$(aws ec2 describe-instances \
  --instance-ids $ID1 $ID2 \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --region $REGION \
  --output text)
 
IPS_ARRAY=($IPS)
 
echo "================================="
echo "🎉 Windows Servers Ready!"
echo "================================="
 
echo "🖥️ Monitor: http://${IPS_ARRAY[0]}"
echo "🌐 Frontend: http://${IPS_ARRAY[1]}"
