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

echo "==========================================="
echo "   AWS DevOps Deployment (Central Control) "
echo "==========================================="

# Export variables so child scripts can use them
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
export LINUX_COUNT WINDOWS_COUNT PROJECT_NAME

# =========================
# EXECUTION
# =========================

echo ""
echo "Launching Linux Infrastructure..."
bash create_linux_instances.sh

echo ""
echo "Launching Windows Infrastructure..."
bash create_windows_instances.sh

echo ""
echo "==========================================="
echo " Deployment Completed Successfully 🚀"
echo "==========================================="