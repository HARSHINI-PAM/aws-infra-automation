#!/bin/bash

AMI_ID="ami-0aaa636894689fa47"

echo "Creating $LINUX_COUNT Linux instances..."

OUTPUT=$(aws ec2 run-instances \
--image-id $AMI_ID \
--count $LINUX_COUNT \
--instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP_ID \
--associate-public-ip-address \
--region $REGION \
--tag-specifications "ResourceType=instance,Tags=[
{Key=Name,Value=Linux-Server},
{Key=Project,Value=$PROJECT_NAME},
{Key=OS,Value=Linux}
]" \
--user-data '#!/bin/bash
yum update -y
yum install nginx docker nodejs -y

systemctl start nginx
systemctl enable nginx

systemctl start docker
systemctl enable docker

docker run -d -p 8080:80 nginx

mkdir /home/ec2-user/api
echo "require(\"http\").createServer((req,res)=>res.end(\"API Running\")).listen(3000)" > /home/ec2-user/api/server.js

node /home/ec2-user/api/server.js &
')

INSTANCE_IDS=$(echo $OUTPUT | jq -r '.Instances[*].InstanceId')

sleep 25

IPS=$(aws ec2 describe-instances \
--instance-ids $INSTANCE_IDS \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output text)

echo "Linux Services:"
for ip in $IPS; do
echo "IP: $ip"
echo " Web → http://$ip"
echo " Docker → http://$ip:8080"
echo " API → http://$ip:3000"
echo "--------------------------"
done