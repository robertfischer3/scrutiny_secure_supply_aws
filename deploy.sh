#!/bin/bash
# deploy.sh - Sequential deployment script for Harbor infrastructure

set -e

# Configuration
ENVIRONMENT=${1:-dev}  # Default to dev if not specified
BASE_DIR="harbor-infrastructure/environments/$ENVIRONMENT"
LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Deployment log
DEPLOY_LOG="$LOG_DIR/deploy_${ENVIRONMENT}_${TIMESTAMP}.log"

# Helper functions
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $DEPLOY_LOG
}

run_terragrunt() {
  local module=$1
  local action=$2
  local module_path="$BASE_DIR/$module"
  
  log "Starting terragrunt $action on $module module..."
  
  if [ -d "$module_path" ]; then
    cd $module_path
    terragrunt $action --terragrunt-non-interactive | tee -a $DEPLOY_LOG
    cd - > /dev/null
    log "Completed terragrunt $action on $module module"
  else
    log "Error: Module directory $module_path does not exist!"
    return 1
  fi
}

wait_for_resource() {
  local resource_type=$1
  local identifier=$2
  local timeout=${3:-300}  # Default timeout: 5 minutes
  
  log "Waiting for $resource_type $identifier to be available..."
  
  case $resource_type in
    "eks")
      aws eks wait cluster-active --name $identifier --region us-east-1 --timeout-seconds $timeout
      ;;
    "vpc")
      aws ec2 wait vpc-available --vpc-ids $identifier --region us-east-1 --timeout-seconds $timeout
      ;;
    "rds")
      aws rds wait db-instance-available --db-instance-identifier $identifier --region us-east-1 --timeout-seconds $timeout
      ;;
    *)
      log "Unknown resource type: $resource_type"
      sleep 60  # Default wait
      ;;
  esac
  
  log "$resource_type $identifier is now available"
}

# Layer 1: Infrastructure Foundation
deploy_layer_1() {
  log "=== Deploying Layer 1: Infrastructure Foundation ==="
  
  # KMS keys first (needed for encrypted resources)
  run_terragrunt "kms" "apply"
  
  # VPC (core networking)
  run_terragrunt "vpc" "apply"
  
  # Wait for VPC to be fully available
  VPC_ID=$(cd $BASE_DIR/vpc && terragrunt output -raw vpc_id)
  wait_for_resource "vpc" $VPC_ID 600
  
  log "Layer 1 deployment complete"
}

# Layer 2: Storage and Database
deploy_layer_2() {
  log "=== Deploying Layer 2: Storage and Database ==="
  
  # S3 buckets
  run_terragrunt "s3" "apply"
  
  # EFS storage
  run_terragrunt "efs" "apply"
  
  # RDS database
  run_terragrunt "rds" "apply"
  
  # Wait for RDS to be available
  RDS_IDENTIFIER=$(cd $BASE_DIR/rds && terragrunt output -raw db_instance_identifier 2>/dev/null || echo "")
  if [ ! -z "$RDS_IDENTIFIER" ]; then
    wait_for_resource "rds" $RDS_IDENTIFIER 1200  # RDS can take a while
  else
    log "Warning: Could not get RDS identifier. Waiting 5 minutes for RDS to initialize..."
    sleep 300
  fi
  
  log "Layer 2 deployment complete"
}

# Layer 3: Compute and Security
deploy_layer_3() {
  log "=== Deploying Layer 3: Compute and Security ==="
  
  # WAF setup
  run_terragrunt "waf" "apply"
  
  # EKS cluster
  run_terragrunt "eks" "apply"
  
  # Wait for EKS to be available
  EKS_CLUSTER=$(cd $BASE_DIR/eks && terragrunt output -raw cluster_name 2>/dev/null || echo "harbor-$ENVIRONMENT")
  wait_for_resource "eks" $EKS_CLUSTER 900  # EKS can take 15 minutes
  
  log "Layer 3 deployment complete"
}

# Layer 4: Application
deploy_layer_4() {
  log "=== Deploying Layer 4: Application ==="
  
  # Harbor registry
  run_terragrunt "harbor" "apply"
  
  # Cloudflare integration
  run_terragrunt "cloudflare" "apply"
  
  log "Layer 4 deployment complete"
}

# Main deployment function
deploy_all() {
  log "Starting deployment for $ENVIRONMENT environment"
  deploy_layer_1
  deploy_layer_2
  deploy_layer_3
  deploy_layer_4
  log "Complete deployment finished successfully for $ENVIRONMENT environment"
}

# Run the deployment
deploy_all