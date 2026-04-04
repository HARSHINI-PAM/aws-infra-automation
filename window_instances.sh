#!/bin/bash
 
WINDOWS_AMI=$(aws ssm get-parameters \
--names /aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base \
--query "Parameters[0].Value" \
--output text \
--region $REGION)
 
echo "🚀 Creating Windows Servers..."
 
# ========================
# 1️⃣ Weather App
# ========================
ID1=$(aws ec2 run-instances \
--image-id $WINDOWS_AMI \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Windows-Weather}]" \
--user-data '<powershell>
Install-WindowsFeature Web-Server
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
New-NetFirewallRule -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
Start-Sleep -Seconds 20
 
$html="<h1>🌦️ Weather App Running</h1>"
Set-Content C:\inetpub\wwwroot\index.html $html
iisreset
</powershell>'
)
 
# ========================
# 2️⃣ Monitoring App
# ========================
ID2=$(aws ec2 run-instances \
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
New-NetFirewallRule -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
Start-Sleep -Seconds 20
 
$cpu=(Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
 
$html="<h1>📊 Monitoring</h1><p>CPU: $cpu %</p>"
Set-Content C:\inetpub\wwwroot\index.html $html
iisreset
</powershell>'
)
 
sleep 90
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)
 
IPS_ARRAY=($IPS)
 
echo "🪟 Windows Ready:"
echo "Weather → http://${IPS_ARRAY[0]}"
echo "Monitor → http://${IPS_ARRAY[1]}"
