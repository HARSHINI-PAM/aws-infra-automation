#!/bin/bash
 
WINDOWS_AMI="ami-060cdb09135556485"
 
echo "🚀 Creating Windows Servers..."
 
# ========================
# 1️⃣ Activity Monitor
# ========================
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
 
$html = "<meta http-equiv=''refresh'' content=''5''><h1>Monitor</h1><p>$hostname</p><p>CPU: " + $cpu.CounterSamples[0].CookedValue + "%</p>"
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
# ========================
# 2️⃣ Frontend Dashboard
# ========================
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
<h1>🌐 DevOps Dashboard</h1>
<p>Use links below after deployment</p>
</body>
</html>
"@
 
Set-Content C:\inetpub\wwwroot\index.html $html
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
echo "⏳ Waiting for Windows..."
sleep 70
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)
 
IPS_ARRAY=($IPS)
 
echo "🪟 Windows Servers Ready:"
echo "Monitor → http://${IPS_ARRAY[0]}"
echo "Frontend → http://${IPS_ARRAY[1]}"
