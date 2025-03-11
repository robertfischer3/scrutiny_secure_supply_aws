# harbor-infrastructure/modules/iam/main.tf

# Create KMS Admin role for Harbor
resource "aws_iam_role" "harbor_kms_admin" {
  name = "HarborKMSAdmin-${var.environment}"
  description = "Admin role for Harbor KMS keys"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.admin_principals
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "HarborKMSAdmin-${var.environment}"
      Environment = var.environment
    }
  )
}

# Create KMS User role for Harbor
resource "aws_iam_role" "harbor_kms_user" {
  name = "HarborKMSUser-${var.environment}"
  description = "User role for Harbor KMS keys with encrypt/decrypt permissions"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "eks.amazonaws.com"]
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.service_principals
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "HarborKMSUser-${var.environment}"
      Environment = var.environment
    }
  )
}

# Create Harbor Admin role
resource "aws_iam_role" "harbor_admin" {
  name = "HarborAdmin-${var.environment}"
  description = "Admin role for Harbor registry management"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "eks.amazonaws.com"]
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.admin_principals
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "HarborAdmin-${var.environment}"
      Environment = var.environment
    }
  )
}

# Create Harbor Operator role
resource "aws_iam_role" "harbor_operator" {
  name = "HarborOperator-${var.environment}"
  description = "Operator role for Harbor registry operations"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com", "eks.amazonaws.com"]
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.operator_principals
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "HarborOperator-${var.environment}"
      Environment = var.environment
    }
  )
}

# Attach basic permissions for KMS Admin
resource "aws_iam_role_policy" "harbor_kms_admin_policy" {
  name = "harbor-kms-admin-policy"
  role = aws_iam_role.harbor_kms_admin.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach KMS usage permissions for Harbor KMS user
resource "aws_iam_role_policy" "harbor_kms_user_policy" {
  name = "harbor-kms-user-policy"
  role = aws_iam_role.harbor_kms_user.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Harbor admin permissions
resource "aws_iam_role_policy" "harbor_admin_policy" {
  name = "harbor-admin-policy"
  role = aws_iam_role.harbor_admin.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Full access to Harbor resources
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          var.harbor_s3_bucket_arn,
          "${var.harbor_s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach Harbor operator permissions
resource "aws_iam_role_policy" "harbor_operator_policy" {
  name = "harbor-operator-policy"
  role = aws_iam_role.harbor_operator.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read-only access to Harbor resources
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.harbor_s3_bucket_arn,
          "${var.harbor_s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Instance profile for Harbor KMS admin (if needed for EC2 instances)
resource "aws_iam_instance_profile" "harbor_kms_admin" {
  count = var.create_instance_profiles ? 1 : 0
  name = "harbor-kms-admin-${var.environment}"
  role = aws_iam_role.harbor_kms_admin.name
}

# Instance profile for Harbor KMS user (if needed for EC2 instances)
resource "aws_iam_instance_profile" "harbor_kms_user" {
  count = var.create_instance_profiles ? 1 : 0
  name = "harbor-kms-user-${var.environment}"
  role = aws_iam_role.harbor_kms_user.name
}

# Instance profile for Harbor admin (if needed for EC2 instances)
resource "aws_iam_instance_profile" "harbor_admin" {
  count = var.create_instance_profiles ? 1 : 0
  name = "harbor-admin-${var.environment}"
  role = aws_iam_role.harbor_admin.name
}

# Instance profile for Harbor operator (if needed for EC2 instances)
resource "aws_iam_instance_profile" "harbor_operator" {
  count = var.create_instance_profiles ? 1 : 0
  name = "harbor-operator-${var.environment}"
  role = aws_iam_role.harbor_operator.name
}