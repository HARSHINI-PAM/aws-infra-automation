#!/bin/bash
 
set -e
 
# ==============================
# CONFIG
# ==============================
 
REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="aws-project-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
echo "================================"
echo "REGION: $REGION"
echo "KEY_NAME: $KEY_NAME"
echo "SECURITY_GROUP_ID: $SECURITY_GROUP_ID"
echo "================================" 
echo "🚀 Starting DevOps Deployment..."
 
# ==============================
# VALIDATION
# ==============================
 
aws sts get-caller-identity > /dev/null || {
    echo "❌ AWS not configured"
    exit 1
}
 
echo "✅ AWS Ready"
 
chmod +x linux_instances.sh window_instances.sh
 
# ==============================
# LINUX DEPLOYMENT
# ==============================
 
echo "🐧 Deploying Linux Servers..."
bash linux_instances.sh
 
# ==============================
# WINDOWS DEPLOYMENT
# ==============================
 
echo "🪟 Deploying Windows Servers..."
bash window_instances.sh
 
# ==============================
# FINAL OUTPUT
# ==============================
 
echo ""
echo "====================================="
echo "🎉 Deployment Completed Successfully"
echo "====================================="
 
echo ""
echo "💡 Check outputs above for public IPs"
 
echo ""
echo "📌 Notes:"
echo "- Linux scripts will print Web, File, Clock URLs"
echo "- Windows script will print Monitor & Frontend URLs"
echo "- If not accessible, wait 1–2 minutes"
