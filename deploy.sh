#!/bin/bash
 
set -e
 
# =========================
# CONFIG (EDIT ONLY HERE)
# =========================
REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="aws-project-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"
 
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
 
# =========================
# VALIDATION
# =========================
echo "🔍 Validating AWS setup..."
 
aws ec2 describe-key-pairs --key-names $KEY_NAME > /dev/null 2>&1 || {
  echo "❌ Key pair not found"
  exit 1
}
 
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID > /dev/null 2>&1 || {
  echo "❌ Security group not found"
  exit 1
}
 
echo "✅ Validation successful"
 
# =========================
# EXECUTE
# =========================
chmod +x linux_instances.sh windows_instances.sh
 
echo "🐧 Deploying Linux..."
./linux_instances.sh
 
echo "🪟 Deploying Windows..."
./windows_instances.sh
 
echo ""
echo "🎉 Deployment Completed"

