#!/bin/bash
WINDOWS_AMI=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2019-English-Full-Base-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Selected Windows AMI: $AMI_ID"
 
if [ -z "$AMI_ID" ]; then
  echo "❌ Windows AMI_ID is empty. Exiting..."
  exit 1
fi 
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
# Enable script execution
Set-ExecutionPolicy Unrestricted -Force
 
# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
# Start IIS
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
 
# Allow HTTP
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
# Wait for IIS
Start-Sleep -Seconds 30
 
# Create Weather UI
$html = @"
<html>
<head>
<title>Weather App</title>
<style>
body{background:#0f172a;color:white;font-family:Arial;text-align:center;margin-top:100px}
.card{background:#1e293b;padding:30px;border-radius:10px}
</style>
</head>
<body>
<div class="card">
<h1>🌦 Weather App</h1>
<p>Location: Auto-detected</p>
<p>Status: Sunny ☀</p>
</div>
</body>
</html>
"@
 
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $html
 
iisreset
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
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
Set-ExecutionPolicy Unrestricted -Force
 
Install-WindowsFeature Web-Server
Start-Service W3SVC
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
Start-Sleep -Seconds 30
 
$cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
$ram = (Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue
 
$html = "<h1>📊 Monitoring Dashboard</h1><p>CPU Usage: $cpu %</p><p>Available RAM: $ram MB</p>"
 
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $html
 
iisreset
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
echo "⏳ Waiting for Windows..."
sleep 120
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)
 
IPS_ARRAY=($IPS)
 
echo "🪟 Windows Ready:"
echo "Weather -> http://${IPS_ARRAY[0]}"
echo "Monitor -> http://${IPS_ARRAY[1]}"
