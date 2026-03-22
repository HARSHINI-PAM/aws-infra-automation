#!/bin/bash
set -e
 
# CONFIG
REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="devops-key"
SECURITY_GROUP_ID="sg-xxxx"
 
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
 
echo "🚀 Starting DevOps Deployment..."
 
# VALIDATION
aws sts get-caller-identity > /dev/null || {
  echo "❌ AWS not configured"
  exit 1
}
 
echo "✅ AWS Ready"
 
chmod +x linux_instances.sh window_instances.sh
 
# LINUX
echo "🐧 Deploying Linux..."
source ./linux_instances.sh
 
# WINDOWS
echo "🪟 Deploying Windows..."
./window_instances.sh
 
echo ""
echo "=================================="
echo "🎉 Deployment Completed"
echo "=================================="
 
echo ""
echo "👉 Linux Web: http://$LINUX_WEB_IP"
echo "👉 File Manager: http://$FILE_MANAGER_IP"
echo "👉 Database: http://$DATABASE_IP"
 
echo ""
echo "⚠️ Open Windows Frontend and replace IPs manually in dashboard if needed"
