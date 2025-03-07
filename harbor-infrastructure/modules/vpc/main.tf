module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  
  # Optional database subnets for RDS (separated from application subnets)
  create_database_subnet_group       = var.create_database_subnet_group
  database_subnets                   = var.database_subnets
  create_database_subnet_route_table = var.create_database_subnet_route_table
  
  # Optional elasticache subnets for Redis
  create_elasticache_subnet_group     = var.create_elasticache_subnet_group
  elasticache_subnets                 = var.elasticache_subnets
  create_elasticache_subnet_route_table = var.create_elasticache_subnet_route_table
  
  # NAT Gateway for outbound internet connectivity from private subnets
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  
  # DNS settings
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = var.manage_default_security_group
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress

  # VPC Flow Logs for network activity monitoring (security requirement for S2C2F)
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role
  flow_log_max_aggregation_interval    = var.flow_log_max_aggregation_interval
  flow_log_destination_type            = var.flow_log_destination_type
  flow_log_log_format                  = var.flow_log_log_format
  flow_log_traffic_type                = var.flow_log_traffic_type
  flow_log_destination_arn             = var.flow_log_destination_arn
  
  # VPC Endpoints for AWS services (no need for internet gateway)
  enable_s3_endpoint              = var.enable_s3_endpoint
  enable_dynamodb_endpoint        = var.enable_dynamodb_endpoint
  s3_endpoint_private_dns_enabled = false # S3 Gateway endpoints don't support private DNS
  
  # Network ACLs
  public_dedicated_network_acl   = var.public_dedicated_network_acl
  private_dedicated_network_acl  = var.private_dedicated_network_acl
  database_dedicated_network_acl = var.database_dedicated_network_acl
  
  public_inbound_acl_rules      = var.public_inbound_acl_rules
  public_outbound_acl_rules     = var.public_outbound_acl_rules
  private_inbound_acl_rules     = var.private_inbound_acl_rules
  private_outbound_acl_rules    = var.private_outbound_acl_rules
  database_inbound_acl_rules    = var.database_inbound_acl_rules
  database_outbound_acl_rules   = var.database_outbound_acl_rules
  
  # Resource tagging
  vpc_tags            = var.vpc_tags
  private_subnet_tags = var.private_subnet_tags
  public_subnet_tags  = var.public_subnet_tags
  database_subnet_tags = var.database_subnet_tags
  
  tags = var.tags
}

# Create additional VPC Endpoints for AWS services
resource "aws_security_group" "vpc_endpoint_sg" {
  count       = var.create_vpc_endpoint_sg ? 1 : 0
  name        = "${var.vpc_name}-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-endpoint-sg"
    }
  )
}

# ECR API endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_ecr_api_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-ecr-api"
    }
  )
}

# ECR DKR endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_dkr_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-ecr-dkr"
    }
  )
}

# KMS endpoint
resource "aws_vpc_endpoint" "kms" {
  count               = var.enable_kms_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-kms"
    }
  )
}

# Secrets Manager endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  count               = var.enable_secretsmanager_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-secretsmanager"
    }
  )
}

# CloudWatch Logs endpoint
resource "aws_vpc_endpoint" "logs" {
  count               = var.enable_logs_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-logs"
    }
  )
}

# SSM endpoint
resource "aws_vpc_endpoint" "ssm" {
  count               = var.enable_ssm_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-ssm"
    }
  )
}

# EC2 endpoint
resource "aws_vpc_endpoint" "ec2" {
  count               = var.enable_ec2_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-ec2"
    }
  )
}

# EFS endpoint
resource "aws_vpc_endpoint" "efs" {
  count               = var.enable_efs_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-efs"
    }
  )
}

# STS endpoint
resource "aws_vpc_endpoint" "sts" {
  count               = var.enable_sts_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.create_vpc_endpoint_sg ? aws_security_group.vpc_endpoint_sg[0].id : var.vpc_endpoint_security_group_id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    var.vpc_endpoint_tags,
    {
      Name = "${var.vpc_name}-sts"
    }
  )
}

# Transit Gateway attachment (optional)
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count              = var.create_tgw_attachment ? 1 : 0
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  
  # Transit Gateway attachment options
  dns_support                                     = var.tgw_dns_support
  ipv6_support                                    = var.tgw_ipv6_support
  appliance_mode_support                          = var.tgw_appliance_mode_support
  transit_gateway_default_route_table_association = var.tgw_default_route_table_association
  transit_gateway_default_route_table_propagation = var.tgw_default_route_table_propagation
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-tgw-attachment"
    }
  )
}

# S2C2F Compliance - Security Group for internal cluster communications
resource "aws_security_group" "harbor_internal" {
  count       = var.create_harbor_internal_sg ? 1 : 0
  name        = "${var.vpc_name}-harbor-internal"
  description = "Security group for Harbor internal communications"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all internal communications"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-harbor-internal"
    }
  )
}

# S2C2F Compliance - Network Firewall (optional)
resource "aws_networkfirewall_firewall" "this" {
  count         = var.enable_network_firewall ? 1 : 0
  name          = "${var.vpc_name}-firewall"
  vpc_id        = module.vpc.vpc_id
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this[0].arn
  
  dynamic "subnet_mapping" {
    for_each = var.network_firewall_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-firewall"
    }
  )
}

resource "aws_networkfirewall_firewall_policy" "this" {
  count = var.enable_network_firewall ? 1 : 0
  name  = "${var.vpc_name}-firewall-policy"
  
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful[0].arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-firewall-policy"
    }
  )
}

resource "aws_networkfirewall_rule_group" "stateful" {
  count    = var.enable_network_firewall ? 1 : 0
  capacity = 100
  name     = "${var.vpc_name}-stateful-rule-group"
  type     = "STATEFUL"
  
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "HTTP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-stateful-rule-group"
    }
  )
}