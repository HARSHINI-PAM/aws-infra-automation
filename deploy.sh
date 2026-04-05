#!/bin/bash
set -euo pipefail
 
LOG_FILE="deploy.log"
exec > >(tee -a "$LOG_FILE") 2>&1
 
REGION="eu-north-1"
INSTANCE_TYPE="t3.micro"
KEY_NAME="aws-project-key"
SECURITY_GROUP_ID="sg-0e2a308bcf9c86f10"
 
export REGION INSTANCE_TYPE KEY_NAME SECURITY_GROUP_ID
 
log() { echo "[DEPLOY] $(date '+%H:%M:%S') $1"; }
 
echo "================================="
echo "🚀 Starting DevOps Deployment"
echo "================================="
 
# VALIDATION
aws ec2 describe-key-pairs --region "$REGION" --key-names "$KEY_NAME" >/dev/null || {
  echo "❌ Key Pair not found"; exit 1;
}
 
aws ec2 describe-security-groups --region "$REGION" --group-ids "$SECURITY_GROUP_ID" >/dev/null || {
  echo "❌ Security Group not found"; exit 1;
}
 
# OPEN PORTS
for port in 22 80 8080 3389; do
  aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port $port \
    --cidr 0.0.0.0/0 2>/dev/null || true
done
 
chmod +x linux_instances.sh window_instances.sh
 
log "🐧 Deploying Linux..."
LINUX_IDS=$(./linux_instances.sh)
 
log "🪟 Deploying Windows..."
WINDOW_IDS=$(./window_instances.sh)
 
# DEBUG (optional but useful)
log "Linux IDs: $LINUX_IDS"
log "Windows IDs: $WINDOW_IDS"
 
ALL_IDS="$LINUX_IDS $WINDOW_IDS"
 
if [[ -z "$ALL_IDS" ]]; then
  echo "❌ No instance IDs found"; exit 1;
fi
 
log "Waiting for instances..."
aws ec2 wait instance-status-ok --region "$REGION" --instance-ids $ALL_IDS
 
log "Fetching Public IPs..."
 
aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids $ALL_IDS \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress]' \
  --output table
 
echo ""
echo "================================="
echo "✅ Deployment Completed!"
echo "🌐 Access apps using above IPs"
echo "================================="
