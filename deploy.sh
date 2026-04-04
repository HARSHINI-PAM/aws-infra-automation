#!/bin/bash
 
set -e
 
# ==============================
# CONFIG (EDIT ONLY HERE)
# ==============================
REGION="eu-north-1"
KEY_NAME="aws-project-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"
INSTANCE_TYPE="t3.micro"
 
echo "🚀 Starting Deployment..."
 
# Export variables
export REGION
export KEY_NAME
export SECURITY_GROUP_ID
export INSTANCE_TYPE
 
# ==============================
# VALIDATE AWS
# ==============================
echo "🔍 Validating AWS setup..."
aws sts get-caller-identity > /dev/null
echo "✅ Validation successful"
 
# ==============================
# LINUX DEPLOYMENT
# ==============================
echo "🐧 Deploying Linux..."
bash linux_instances.sh
 
# ==============================
# WINDOWS DEPLOYMENT
# ==============================
echo "🪟 Deploying Windows..."
bash window_instances.sh
 
echo "🎉 Deployment Complete!"
