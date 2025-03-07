variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "create_database_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = false
}

variable "create_database_subnet_route_table" {
  description = "Whether to create a database subnet route table"
  type        = bool
  default     = false
}

variable "elasticache_subnets" {
  description = "List of elasticache subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "create_elasticache_subnet_group" {
  description = "Whether to create an elasticache subnet group"
  type        = bool
  default     = false
}

variable "create_elasticache_subnet_route_table" {
  description = "Whether to create an elasticache subnet route table"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway(s)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Whether to use one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "manage_default_security_group" {
  description = "Whether to manage the default security group"
  type        = bool
  default     = true
}

variable "default_security_group_ingress" {
  description = "List of ingress rules for the default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_egress" {
  description = "List of egress rules for the default security group"
  type        = list(map(string))
  default     = []
}

# VPC Flow Logs
variable "enable_flow_log" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_iam_role" {
  description = "Whether to create IAM role for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_max_aggregation_interval" {
  description = "Maximum interval of aggregation for VPC Flow Logs (in seconds)"
  type        = number
  default     = 600
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_log_format" {
  description = "Format of the flow log data"
  type        = string
  default     = null
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
}

variable "flow_log_destination_arn" {
  description = "ARN of the CloudWatch log group or S3 bucket for VPC Flow Logs"
  type        = string
  default     = null
}

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "Whether to enable S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Whether to enable DynamoDB VPC endpoint"
  type        = bool
  default     = false
}

variable "create_vpc_endpoint_sg" {
  description = "Whether to create a security group for VPC endpoints"
  type        = bool
  default     = true
}

variable "vpc_endpoint_security_group_id" {
  description = "ID of an existing security group to use for VPC endpoints"
  type        = string
  default     = ""
}

variable "enable_ecr_api_endpoint" {
  description = "Whether to enable ECR API VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  description = "Whether to enable ECR DKR VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_kms_endpoint" {
  description = "Whether to enable KMS VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_secretsmanager_endpoint" {
  description = "Whether to enable Secrets Manager VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Whether to enable CloudWatch Logs VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ssm_endpoint" {
  description = "Whether to enable SSM VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_ec2_endpoint" {
  description = "Whether to enable EC2 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_efs_endpoint" {
  description = "Whether to enable EFS VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_sts_endpoint" {
  description = "Whether to enable STS VPC endpoint"
  type        = bool
  default     = true
}

variable "vpc_endpoint_tags" {
  description = "Additional tags for the VPC endpoints"
  type        = map(string)
  default     = {}
}

# Network ACLs
variable "public_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for public subnets"
  type        = bool
  default     = true
}

variable "private_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for private subnets"
  type        = bool
  default     = true
}

variable "database_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL for database subnets"
  type        = bool
  default     = true
}

variable "public_inbound_acl_rules" {
  description = "List of inbound rules for public subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "public_outbound_acl_rules" {
  description = "List of outbound rules for public subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "private_inbound_acl_rules" {
  description = "List of inbound rules for private subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "private_outbound_acl_rules" {
  description = "List of outbound rules for private subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "database_inbound_acl_rules" {
  description = "List of inbound rules for database subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "database_outbound_acl_rules" {
  description = "List of outbound rules for database subnets"
  type        = list(map(string))
  default     = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

# Transit Gateway
variable "create_tgw_attachment" {
  description = "Whether to create a Transit Gateway attachment"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  type        = string
  default     = ""
}

variable "tgw_dns_support" {
  description = "Whether to enable DNS support for the Transit Gateway attachment"
  type        = string
  default     = "enable"
}

variable "tgw_ipv6_support" {
  description = "Whether to enable IPv6 support for the Transit Gateway attachment"
  type        = string
  default     = "disable"
}

variable "tgw_appliance_mode_support" {
  description = "Whether to enable appliance mode support for the Transit Gateway attachment"
  type        = string
  default     = "disable"
}

variable "tgw_default_route_table_association" {
  description = "Whether to associate with the default Transit Gateway route table"
  type        = bool
  default     = true
}

variable "tgw_default_route_table_propagation" {
  description = "Whether to propagate routes to the default Transit Gateway route table"
  type        = bool
  default     = true
}

# Harbor internal security group
variable "create_harbor_internal_sg" {
  description = "Whether to create a security group for Harbor internal communications"
  type        = bool
  default     = true
}

# Network Firewall
variable "enable_network_firewall" {
  description = "Whether to enable AWS Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_subnet_ids" {
  description = "List of subnet IDs for Network Firewall deployment"
  type        = list(string)
  default     = []
}

# AWS Region
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for the database subnets"
  type        = map(string)
  default     = {}
}