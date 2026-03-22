#!/bin/bash

# =========================
# CONFIGURATION (EDIT HERE ONLY)
# =========================

REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="devops-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"

LINUX_COUNT=3
WINDOWS_COUNT=2

PROJECT_NAME="DevOpsAutomation"
# =========================
# INSTANCE NAMES (EDIT HERE)
# =========================

LINUX_NAMES="Linux-Dashboard,Linux-Docker,Linux-API"
WINDOWS_NAMES="Windows-Control,Windows-Monitor"

export LINUX_NAMES WINDOWS_NAMES
echo "==========================================="
echo "   AWS DevOps Deployment (Central Control) "
echo "==========================================="

# =========================
# VALIDATION (VERY IMPORTANT)
# =========================

echo "Validating AWS resources..."

aws ec2 describe-key-pairs --key-names $KEY_NAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Key Pair '$KEY_NAME' not found!"
  exit 1
fi

aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Security Group '$SECURITY_GROUP_ID' not found!"
  exit 1
fi

echo "✅ Validation successful"

# =========================
# EXPORT VARIABLES
# =========================

export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
export LINUX_COUNT WINDOWS_COUNT PROJECT_NAME

# =========================
# EXECUTION
# =========================

chmod +x linux_instances.sh
chmod +x window_instances.sh

echo ""
echo "🚀 Launching Linux Infrastructure..."
./linux_instances.sh

echo ""
echo "🚀 Launching Windows Infrastructure..."
./window_instances.sh

echo ""
echo "==========================================="
echo " 🎉 Deployment Completed Successfully"
echo "==========================================="
