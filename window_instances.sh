#!/bin/bash
 
echo "🚀 Creating Windows Server..."
 
# ==============================
# DYNAMIC WINDOWS AMI (FIXED)
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Selected Windows AMI: $AMI_ID"
 
if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo "❌ Windows AMI_ID is empty. Exiting..."
  exit 1
fi
 
# ==============================
# INSTANCE CREATION
# ==============================
ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --associate-public-ip-address \
  --region $REGION \
  --query "Instances[0].InstanceId" \
  --output text)
 
echo "Instance ID: $ID"
 
if [ -z "$ID" ]; then
  echo "❌ Windows instance creation failed"
  exit 1
fi
 
# ==============================
# WAIT
# ==============================
echo "⏳ Waiting for Windows instance..."
sleep 40
 
IP=$(aws ec2 describe-instances \
  --instance-ids $ID \
  --region $REGION \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)
 
echo "🌐 Windows Server Ready: http://$IP"
