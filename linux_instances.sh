#!/bin/bash
 
echo "🚀 Creating Linux Servers..."
 
# ==============================
# DYNAMIC AMI (FIXED)
# ==============================
AMI_ID=$(aws ec2 describe-images \
  --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --output text)
 
echo "✅ Selected Linux AMI: $AMI_ID"
 
if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
  echo "❌ AMI_ID is empty. Exiting..."
  exit 1
fi
 
# ==============================
# INSTANCE CREATION
# ==============================
ID1=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --associate-public-ip-address \
  --region $REGION \
  --query "Instances[0].InstanceId" \
  --output text)
 
echo "Instance ID: $ID1"
 
if [ -z "$ID1" ]; then
  echo "❌ Instance creation failed"
  exit 1
fi
 
# ==============================
# WAIT FOR INSTANCE
# ==============================
echo "⏳ Waiting for instance..."
sleep 20
 
IP=$(aws ec2 describe-instances \
  --instance-ids $ID1 \
  --region $REGION \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)
 
echo "🌐 Linux Server Ready: http://$IP"
