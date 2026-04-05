#!/bin/bash
set -euo pipefail
 
echo "🚀 Creating Windows Servers..." >&2
 
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
  --query "Images | sort_by(@,&CreationDate)[-1].ImageId" \
  --output text)
 
[[ "$AMI_ID" =~ ^ami- ]] || { echo "❌ AMI fetch failed" >&2; exit 1; }
 
echo "Using AMI: $AMI_ID" >&2
 
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
 
  [[ "$ID" =~ ^i- ]] || { echo "❌ Instance launch failed" >&2; exit 1; }
 
  echo "$ID"
}
 
IDS=""
 
# CLOCK
IDS+=" $(launch_instance "Windows-Clock" '<powershell>
Install-WindowsFeature Web-Server
Start-Service W3SVC
 
while ((Get-Service W3SVC).Status -ne "Running") { Start-Sleep 2 }
 
Remove-Item "C:\inetpub\wwwroot\iisstart.htm" -ErrorAction SilentlyContinue
 
$html = @"
<html>
<body style="background:#0f172a;color:#38bdf8;text-align:center;font-family:Arial">
<h1>🌍 Global Clock</h1>
<p id="clock"></p>
<script>
setInterval(function(){
document.getElementById("clock").innerHTML =
"IST: "+new Date().toLocaleString()+"<br>"+
"GMT: "+new Date().toUTCString();
},1000)
</script>
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
iisreset
</powershell>')"
 
# MONITOR
IDS+=" $(launch_instance "Windows-Monitor" '<powershell>
Install-WindowsFeature Web-Server
Start-Service W3SVC
 
while ((Get-Service W3SVC).Status -ne "Running") { Start-Sleep 2 }
 
Remove-Item "C:\inetpub\wwwroot\iisstart.htm" -ErrorAction SilentlyContinue
 
$cpu = (Get-Counter '\''\Processor(_Total)\% Processor Time'\'').CounterSamples.CookedValue
$cpu = [math]::Round($cpu,2)
$ram = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
 
$html = @"
<html>
<body style="background:#111;color:#00ffcc;text-align:center;font-family:Arial">
<h1>🖥 System Monitor</h1>
<p>CPU: $cpu %</p>
<p>Free RAM: $ram</p>
<meta http-equiv="refresh" content="5">
</body>
</html>
"@
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
iisreset
</powershell>')"
 
echo "✅ Windows servers created" >&2
echo $IDS
 
