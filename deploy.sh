#!/bin/bash
 
set -e
 
# ======================
# CONFIG (EDIT HERE ONLY)
# ======================
REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="aws-project-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"
 
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
 
echo "================================="
echo "🚀 Starting DevOps Deployment"
echo "================================="
 
# Validate AWS
aws ec2 describe-key-pairs --key-names $KEY_NAME > /dev/null 2>&1 || {
  echo "❌ Key Pair not found"
  exit 1
}
 
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID > /dev/null 2>&1 || {
  echo "❌ Security Group not found"
  exit 1
}
 
chmod +x linux_instances.sh
chmod +x window_instances.sh
 
echo "🐧 Deploying Linux Servers..."
./linux_instances.sh
 
echo "🪟 Deploying Windows Servers..."
./window_instances.sh
 
echo ""
echo "✅ Deployment Completed!"
echo "👉 Wait 3–5 minutes before accessing apps"
