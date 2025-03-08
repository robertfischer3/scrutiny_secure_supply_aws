output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table of the VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = module.vpc.vpc_owner_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.vpc.database_subnet_arns
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "elasticache_subnet_arns" {
  description = "List of ARNs of elasticache subnets"
  value       = module.vpc.elasticache_subnet_arns
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of CIDR blocks of elasticache subnets"
  value       = module.vpc.elasticache_subnets_cidr_blocks
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = module.vpc.elasticache_subnet_group_name
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = module.vpc.database_route_table_ids
}

output "elasticache_route_table_ids" {
  description = "List of IDs of elasticache route tables"
  value       = module.vpc.elasticache_route_table_ids
}

output "nat_ids" {
  description = "List of allocation IDs of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

output "default_vpc_id" {
  description = "The ID of the default VPC"
  value       = module.vpc.default_vpc_id
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the default VPC"
  value       = module.vpc.default_vpc_cidr_block
}

output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the Flow Log destination"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "The type of the Flow Log destination"
  value       = module.vpc.vpc_flow_log_destination_type
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used for the Flow Log CloudWatch logs"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

# Additional VPC Endpoints created by this module
output "vpc_endpoint_ecr_api_id" {
  description = "The ID of VPC endpoint for ECR API"
  value       = var.enable_ecr_api_endpoint ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "The ID of VPC endpoint for ECR DKR"
  value       = var.enable_ecr_dkr_endpoint ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "vpc_endpoint_kms_id" {
  description = "The ID of VPC endpoint for KMS"
  value       = var.enable_kms_endpoint ? aws_vpc_endpoint.kms[0].id : null
}

output "vpc_endpoint_secretsmanager_id" {
  description = "The ID of VPC endpoint for Secrets Manager"
  value       = var.enable_secretsmanager_endpoint ? aws_vpc_endpoint.secretsmanager[0].id : null
}

output "vpc_endpoint_logs_id" {
  description = "The ID of VPC endpoint for CloudWatch Logs"
  value       = var.enable_logs_endpoint ? aws_vpc_endpoint.logs[0].id : null
}

output "vpc_endpoint_ssm_id" {
  description = "The ID of VPC endpoint for SSM"
  value       = var.enable_ssm_endpoint ? aws_vpc_endpoint.ssm[0].id : null
}

output "vpc_endpoint_ec2_id" {
  description = "The ID of VPC endpoint for EC2"
  value       = var.enable_ec2_endpoint ? aws_vpc_endpoint.ec2[0].id : null
}

output "vpc_endpoint_efs_id" {
  description = "The ID of VPC endpoint for EFS"
  value       = var.enable_efs_endpoint ? aws_vpc_endpoint.efs[0].id : null
}

output "vpc_endpoint_sts_id" {
  description = "The ID of VPC endpoint for STS"
  value       = var.enable_sts_endpoint ? aws_vpc_endpoint.sts[0].id : null
}

# S2C2F compliance resources
output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group for VPC endpoints"
  value       = var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id
}

output "harbor_internal_security_group_id" {
  description = "The ID of the security group for Harbor internal communications"
  value       = var.create_harbor_internal_sg ? aws_security_group.harbor_internal[0].id : null
}

output "transit_gateway_attachment_id" {
  description = "The ID of the Transit Gateway VPC attachment"
  value       = var.create_tgw_attachment ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
}

output "network_firewall_id" {
  description = "The ID of the Network Firewall"
  value       = var.enable_network_firewall ? aws_networkfirewall_firewall.this[0].id : null
}

output "network_firewall_policy_id" {
  description = "The ID of the Network Firewall policy"
  value       = var.enable_network_firewall ? aws_networkfirewall_firewall_policy.this[0].id : null
}