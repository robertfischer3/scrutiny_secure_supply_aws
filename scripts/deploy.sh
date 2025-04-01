#!/bin/bash
# deploy.sh - Sequential deployment script for Harbor infrastructure

set -e

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of the script directory)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Configuration
ENVIRONMENT=${1:-dev}  # Default to dev if not specified
BASE_DIR="${PROJECT_ROOT}/harbor-infrastructure/environments/$ENVIRONMENT"
LOG_DIR="${PROJECT_ROOT}/logs"
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
    # Save current directory
    CURRENT_DIR=$(pwd)
    # Change to module directory
    cd $module_path
    terragrunt $action --terragrunt-non-interactive | tee -a $DEPLOY_LOG
    # Return to previous directory
    cd "$CURRENT_DIR"
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
      # Use a loop instead of relying on the timeout parameter
      local end_time=$(($(date +%s) + timeout))
      while [ $(date +%s) -lt $end_time ]; do
        if aws eks describe-cluster --name $identifier --region us-west-2 --query 'cluster.status' --output text 2>/dev/null | grep -q ACTIVE; then
          break
        fi
        sleep 30
        log "Still waiting for EKS cluster $identifier..."
      done
      ;;
    "vpc")
      # Use a loop instead of relying on the timeout parameter
      local end_time=$(($(date +%s) + timeout))
      while [ $(date +%s) -lt $end_time ]; do
        if aws ec2 describe-vpcs --vpc-ids $identifier --region us-west-2 --query 'Vpcs[0].State' --output text 2>/dev/null | grep -q available; then
          break
        fi
        sleep 10
        log "Still waiting for VPC $identifier..."
      done
      ;;
    "rds")
      # Use a loop instead of relying on the timeout parameter
      local end_time=$(($(date +%s) + timeout))
      while [ $(date +%s) -lt $end_time ]; do
        if aws rds describe-db-instances --db-instance-identifier $identifier --region us-west-2 --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null | grep -q available; then
          break
        fi
        sleep 30
        log "Still waiting for RDS instance $identifier..."
      done
      ;;
    *)
      log "Unknown resource type: $resource_type"
      sleep 60  # Default wait
      ;;
  esac
  
  log "$resource_type $identifier is now available"
}

deploy_layer_0() {
  log "=== Deploying Layer 0: Identity and Access Management ==="
  
  # IAM roles and policies (needed for KMS and other resources)
  run_terragrunt "iam" "apply"
  
  log "Layer 0 deployment complete"
}

# Layer 1: Infrastructure Foundation
deploy_layer_1() {
  log "=== Deploying Layer 1: Infrastructure Foundation ==="
  
  # KMS keys first (needed for encrypted resources)
  run_terragrunt "kms" "apply"
  
  # VPC (core networking)
  run_terragrunt "vpc" "apply"
  
  # Wait for VPC to be fully available
  # Save current directory before changing to VPC module
  CURRENT_DIR=$(pwd)
  cd $BASE_DIR/vpc
  VPC_ID=$(terragrunt output -raw vpc_id)
  # Return to previous directory
  cd "$CURRENT_DIR"
  
  wait_for_resource "vpc" $VPC_ID 600
  
  log "Layer 1 deployment complete"
}

# Layer 2: Storage and Database
deploy_layer_2() {
  log "=== Deploying Layer 2: Storage and Database ==="
  
  echo "Deploying S3 buckets..."
  # S3 buckets
  run_terragrunt "s3" "apply"
  
  echo "Deploying SNS..."
  # SNS topics (if needed for S3 notifications)
  if [ -d "$BASE_DIR/sns" ]; then
    run_terragrunt "sns" "apply"
  
    # S3 notifications (if module exists)
    if [ -d "$BASE_DIR/s3-notifications" ]; then
      run_terragrunt "s3-notifications" "apply"
    fi
  fi
  
  echo "Deploying EFS..."
  # EFS storage
  run_terragrunt "efs" "apply"
  
  echo "Deploying RDS..."
  # RDS database
  run_terragrunt "rds" "apply"
  
  # Wait for RDS to be available
  # Save current directory before changing to RDS module
  CURRENT_DIR=$(pwd)
  cd $BASE_DIR/rds
  RDS_IDENTIFIER=$(terragrunt output -raw db_instance_identifier 2>/dev/null || echo "")
  # Return to previous directory
  cd "$CURRENT_DIR"
  
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
  # Save current directory before changing to EKS module
  CURRENT_DIR=$(pwd)
  cd $BASE_DIR/eks
  EKS_CLUSTER=$(terragrunt output -raw cluster_name 2>/dev/null || echo "harbor-$ENVIRONMENT")
  # Return to previous directory
  cd "$CURRENT_DIR"
  
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
  deploy_layer_0
  deploy_layer_1
  deploy_layer_2
  # deploy_layer_3
  # deploy_layer_4
  log "Complete deployment finished successfully for $ENVIRONMENT environment"
}

# Run the deployment
deploy_all