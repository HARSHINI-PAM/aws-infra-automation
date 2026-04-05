#!/bin/bash
 
echo "🚀 Creating Windows Servers..."
 
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo "❌ Windows AMI not found"
  exit 1
fi
 
echo "✅ Windows AMI: $AMI_ID"
 
# ==============================
# 1️⃣ CLOCK SERVER
# ==============================
aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Windows-Clock}]' \
--user-data '<powershell>
 
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
 
Start-Sleep -Seconds 120
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Global Clock</title>
<style>
body {background:#0f2027;color:white;text-align:center;font-family:Arial;}
.clock {margin:20px;padding:20px;background:#1c1c1c;border-radius:10px;display:inline-block;}
</style>
</head>
<body>
 
<h1>🌍 Global Clock</h1>
 
<div class="clock">
<h2>🇮🇳 IST</h2>
<div id="ist"></div>
</div>
 
<div class="clock">
<h2>🇺🇸 PST</h2>
<div id="pst"></div>
</div>
 
<div class="clock">
<h2>🌍 GMT</h2>
<div id="gmt"></div>
</div>
 
<script>
function updateTime() {
  const now = new Date();
  document.getElementById("ist").innerHTML = new Date(now.toLocaleString("en-US",{timeZone:"Asia/Kolkata"})).toLocaleTimeString();
  document.getElementById("pst").innerHTML = new Date(now.toLocaleString("en-US",{timeZone:"America/Los_Angeles"})).toLocaleTimeString();
  document.getElementById("gmt").innerHTML = new Date(now.toLocaleString("en-US",{timeZone:"GMT"})).toLocaleTimeString();
}
setInterval(updateTime,1000);
updateTime();
</script>
 
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
iisreset
 
</powershell>'
 
# ==============================
# 2️⃣ MONITOR SERVER
# ==============================
aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Windows-Monitor}]' \
--user-data '<powershell>
 
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
 
Start-Sleep -Seconds 120
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
$cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
$ram = (Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue
 
$html = @"
<html>
<head>
<title>Monitoring</title>
<style>
body {background:#141E30;color:white;text-align:center;font-family:Arial;}
.card {margin-top:100px;}
</style>
</head>
<body>
 
<div class="card">
<h1>💻 System Monitoring</h1>
<p>CPU: $cpu %</p>
<p>RAM: $ram MB</p>
</div>
 
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
iisreset
 
</powershell>'
 
echo "⏳ Windows servers launched"
 
