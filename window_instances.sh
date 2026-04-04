#!/bin/bash
 
echo "🚀 Creating Windows Servers..."
 
# ==============================
# DYNAMIC WINDOWS AMI
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Windows AMI: $AMI_ID"
 
if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo "❌ Windows AMI not found"
  exit 1
fi
 
# ==============================
# 1️⃣ CLOCK SERVER
# ==============================
echo "🕒 Creating Clock Server..."
 
ID1=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Windows-Clock}]' \
--user-data '<powershell>
 
Set-ExecutionPolicy Bypass -Force
 
$script = @"
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
Start-Sleep -Seconds 60
 
$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Global Clock Dashboard</title>
<style>
body {
  font-family: Arial;
  background: linear-gradient(to right,#0f2027,#203a43,#2c5364);
  color: white;
  text-align: center;
}
.container {
  margin-top: 80px;
}
.clock {
  background: rgba(255,255,255,0.1);
  margin: 20px;
  padding: 30px;
  border-radius: 10px;
  display: inline-block;
}
h1 { color: #00d4ff; }
.time { font-size: 30px; margin-top: 10px; }
</style>
</head>
<body>
 
<div class="container">
<h1>🌍 Global Time Dashboard</h1>
 
<div class="clock">
<h2>🇮🇳 IST</h2>
<div id="ist" class="time"></div>
</div>
 
<div class="clock">
<h2>🇺🇸 PST</h2>
<div id="pst" class="time"></div>
</div>
 
<div class="clock">
<h2>🌍 GMT</h2>
<div id="gmt" class="time"></div>
</div>
 
</div>
 
<script>
function updateTime() {
  const now = new Date();
 
  const ist = new Date(now.toLocaleString("en-US", {timeZone: "Asia/Kolkata"}));
  const pst = new Date(now.toLocaleString("en-US", {timeZone: "America/Los_Angeles"}));
  const gmt = new Date(now.toLocaleString("en-US", {timeZone: "GMT"}));
 
  document.getElementById("ist").innerHTML = ist.toLocaleTimeString();
  document.getElementById("pst").innerHTML = pst.toLocaleTimeString();
  document.getElementById("gmt").innerHTML = gmt.toLocaleTimeString();
}
 
setInterval(updateTime, 1000);
updateTime();
</script>
 
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
 
iisreset
"@
 
Set-Content -Path "C:\setup.ps1" -Value $script
 
schtasks /create /tn "ClockSetup" /tr "powershell -ExecutionPolicy Bypass -File C:\setup.ps1" /sc onstart /ru SYSTEM
 
powershell -ExecutionPolicy Bypass -File C:\setup.ps1
 
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
echo "Clock Instance: $ID1"
 
# ==============================
# 2️⃣ MONITORING SERVER
# ==============================
echo "💻 Creating Monitoring Server..."
 
ID2=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Windows-Monitor}]' \
--user-data '<powershell>
 
Set-ExecutionPolicy Bypass -Force
 
$script = @"
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
Start-Service W3SVC
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
Start-Sleep -Seconds 60
 
$cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
$ram = (Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue
 
$html = @"
<!DOCTYPE html>
<html>
<head>
<title>System Monitoring</title>
<style>
body {
  background: linear-gradient(to right,#141E30,#243B55);
  color: white;
  font-family: Arial;
  text-align: center;
}
.card {
  margin-top: 100px;
  background: rgba(255,255,255,0.1);
  padding: 40px;
  border-radius: 10px;
}
</style>
</head>
<body>
 
<div class="card">
<h1>💻 System Monitoring Dashboard</h1>
 
<p><b>CPU Usage:</b> $cpu %</p>
<p><b>Available RAM:</b> $ram MB</p>
 
<p>This dashboard provides system insights using PowerShell.</p>
 
</div>
 
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
 
iisreset
"@
 
Set-Content -Path "C:\setup.ps1" -Value $script
 
schtasks /create /tn "MonitorSetup" /tr "powershell -ExecutionPolicy Bypass -File C:\setup.ps1" /sc onstart /ru SYSTEM
 
powershell -ExecutionPolicy Bypass -File C:\setup.ps1
 
</powershell>' \
--query "Instances[0].InstanceId" \
--output text)
 
echo "Monitor Instance: $ID2"
 
# ==============================
# WAIT & OUTPUT
# ==============================
echo "⏳ Waiting for servers..."
sleep 180
 
IPS=$(aws ec2 describe-instances \
--instance-ids $ID1 $ID2 \
--region $REGION \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output text)
 
IPS_ARRAY=($IPS)
 
echo ""
echo "🪟 Windows Servers Ready:"
echo "🕒 Clock   → http://${IPS_ARRAY[0]}"
echo "💻 Monitor → http://${IPS_ARRAY[1]}"
