#!/bin/bash
 
echo "🚀 Creating Windows Servers..."
 
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "Using AMI: $AMI_ID"
 
# ================= CLOCK =================
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
 
Start-Sleep -Seconds 180
Remove-Item "C:\inetpub\wwwroot\iisstart.htm" -ErrorAction SilentlyContinue
 
$html = "<h1 style=''color:white;text-align:center;background:black;''>🌍 Global Clock Running</h1>"
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
iisreset
 
</powershell>'
 
# ================= MONITOR =================
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
 
Start-Sleep -Seconds 180
Remove-Item "C:\inetpub\wwwroot\iisstart.htm" -ErrorAction SilentlyContinue
 
$cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
 
$html = "<h1>CPU Usage: $cpu %</h1>"
 
Set-Content "C:\inetpub\wwwroot\index.html" $html
 
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
 
iisreset
 
</powershell>'
 
echo "✅ Windows servers created"
