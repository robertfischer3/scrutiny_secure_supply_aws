#!/bin/bash
# destroy.sh - Sequential destruction script for Harbor infrastructure

set -e

# Configuration
ENVIRONMENT=${1:-dev}  # Default to dev if not specified
BASE_DIR="harbor-infrastructure/environments/$ENVIRONMENT"
LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Destroy log
DESTROY_LOG="$LOG_DIR/destroy_${ENVIRONMENT}_${TIMESTAMP}.log"

# Helper functions
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a $DESTROY_LOG
}

run_terragrunt_destroy() {
  local module=$1
  local module_path="$BASE_DIR/$module"
  
  log "Starting terragrunt destroy on $module module..."
  
  if [ -d "$module_path" ]; then
    cd $module_path
    terragrunt destroy --terragrunt-non-interactive --auto-approve | tee -a $DESTROY_LOG
    
    # Check if destroy failed
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      log "Warning: Destroy operation for $module may have encountered issues"
    else
      log "Completed terragrunt destroy on $module module"
    fi
    
    cd - > /dev/null
  else
    log "Error: Module directory $module_path does not exist!"
    return 1
  fi
}

check_resource_exists() {
  local resource_type=$1
  local identifier=$2
  
  case $resource_type in
    "eks")
      aws eks describe-cluster --name $identifier --region us-west-2 >/dev/null 2>&1
      return $?
      ;;
    "vpc")
      aws ec2 describe-vpcs --vpc-ids $identifier --region us-west-2 >/dev/null 2>&1
      return $?
      ;;
    "rds")
      aws rds describe-db-instances --db-instance-identifier $identifier --region us-west-2 >/dev/null 2>&1
      return $?
      ;;
    *)
      log "Unknown resource type: $resource_type"
      return 1
      ;;
  esac
}

wait_for_resource_deletion() {
  local resource_type=$1
  local identifier=$2
  local timeout=${3:-300}  # Default timeout: 5 minutes
  local start_time=$(date +%s)
  local end_time=$((start_time + timeout))
  
  log "Waiting for $resource_type $identifier to be deleted..."
  
  while [ $(date +%s) -lt $end_time ]; do
    if ! check_resource_exists $resource_type $identifier; then
      log "$resource_type $identifier has been deleted"
      return 0
    fi
    sleep 30
  done
  
  log "Warning: Timed out waiting for $resource_type $identifier to be deleted"
  return 1
}

# Layer 4: Application (reverse of deployment)
destroy_layer_4() {
  log "=== Destroying Layer 4: Application ==="
  
  # Cloudflare integration
  run_terragrunt_destroy "cloudflare"
  
  # Harbor registry
  run_terragrunt_destroy "harbor"
  
  log "Layer 4 destruction complete"
}

# Layer 3: Compute and Security
destroy_layer_3() {
  log "=== Destroying Layer 3: Compute and Security ==="
  
  # Get EKS cluster name before destroying
  EKS_CLUSTER=$(cd $BASE_DIR/eks && terragrunt output -raw cluster_name 2>/dev/null || echo "harbor-$ENVIRONMENT")
  
  # EKS cluster
  run_terragrunt_destroy "eks"
  
  # Wait for EKS to be deleted
  if [ ! -z "$EKS_CLUSTER" ]; then
    wait_for_resource_deletion "eks" $EKS_CLUSTER 1800  # EKS deletion can take 30+ minutes
  fi
  
  # WAF setup
  run_terragrunt_destroy "waf"
  
  log "Layer 3 destruction complete"
}

# Layer 2: Storage and Database
destroy_layer_2() {
  log "=== Destroying Layer 2: Storage and Database ==="
  
  # Get RDS identifier before destroying
  RDS_IDENTIFIER=$(cd $BASE_DIR/rds && terragrunt output -raw db_instance_identifier 2>/dev/null || echo "")
  
  echo "RDS Identifier: $RDS_IDENTIFIER"
  # RDS database
  run_terragrunt_destroy "rds"
  
  # Wait for RDS to be deleted
  if [ ! -z "$RDS_IDENTIFIER" ]; then
    wait_for_resource_deletion "rds" $RDS_IDENTIFIER 1800  # RDS deletion can take 30+ minutes
  fi
  
  # EFS storage
  run_terragrunt_destroy "efs"
  
  # S3 buckets
  run_terragrunt_destroy "s3"
  
  log "Layer 2 destruction complete"
}

# Layer 1: Infrastructure Foundation
destroy_layer_1() {
  log "=== Destroying Layer 1: Infrastructure Foundation ==="
  
  # Get VPC ID before destroying
  VPC_ID=$(cd $BASE_DIR/vpc && terragrunt output -raw vpc_id 2>/dev/null || echo "")
  
  # VPC (core networking)
  run_terragrunt_destroy "vpc"
  
  # Wait for VPC to be deleted
  if [ ! -z "$VPC_ID" ]; then
    wait_for_resource_deletion "vpc" $VPC_ID 900
  fi
  
  # KMS keys last
  run_terragrunt_destroy "kms"
  
  log "Layer 1 destruction complete"
}

# Force destroy function - use with caution
force_destroy_all() {
  log "WARNING: Forcing destruction of all resources for $ENVIRONMENT environment"
  log "This might result in orphaned resources if dependencies aren't handled correctly"
  
  # Force destroy order - inverted dependency chain
  MODULES=("cloudflare" "harbor" "waf" "eks" "rds" "efs" "s3" "vpc" "kms")
  
  for module in "${MODULES[@]}"; do
    log "Force destroying module: $module"
    run_terragrunt_destroy $module || log "Failed to destroy $module, continuing anyway"
    sleep 10  # Small pause between operations
  done
  
  log "Force destruction completed. Please check AWS Console for any orphaned resources"
}

# Main destruction function
destroy_all() {
  log "Starting destruction for $ENVIRONMENT environment"
  
  if [ "$2" == "--force" ]; then
    force_destroy_all
  else
    destroy_layer_4
    destroy_layer_3
    destroy_layer_2
    destroy_layer_1
  fi
  
  log "Complete destruction finished for $ENVIRONMENT environment"
}

# Run the destruction
destroy_all $@