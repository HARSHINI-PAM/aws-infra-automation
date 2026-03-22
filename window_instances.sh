#!/bin/bash

WINDOWS_AMI="ami-071a03d52b61d8f52"

echo "Creating $WINDOWS_COUNT Windows instances..."

INSTANCE_IDS=$(aws ec2 run-instances \
--image-id $WINDOWS_AMI \
--count $WINDOWS_COUNT \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[
{Key=Name,Value=Windows-Server},
{Key=Project,Value=$PROJECT_NAME},
{Key=OS,Value=Windows}
]" \
--user-data '<powershell>
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

$html="<h1>DevOps Windows Server</h1><p>Status: Running</p>"

Set-Content -Path C:\inetpub\wwwroot\index.html -Value $html
</powershell>' \
--query 'Instances[*].InstanceId' \
--output text)

echo "Instances created: $INSTANCE_IDS"

echo "Waiting for instances to initialize..."
sleep 60

IPS=$(aws ec2 describe-instances \
--instance-ids $INSTANCE_IDS \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)

echo "-----------------------------------"
echo "Windows Applications Deployed:"
echo "-----------------------------------"

for ip in $IPS; do
echo "Server IP: $ip"
echo " IIS Portal → http://$ip"
echo "-----------------------------------"
done