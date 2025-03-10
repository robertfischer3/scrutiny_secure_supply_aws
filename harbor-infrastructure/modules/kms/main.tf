
# Lookup existing key if provided
data "aws_kms_key" "existing" {
  count  = var.is_testing_mode && var.existing_key_id != "" ? 1 : 0
  key_id = var.existing_key_id
}

locals {
  # Determine if we should create a new key
  create_key = !var.skip_creation && (var.existing_key_id == "" || !var.is_testing_mode)

  # Key ID to use (either from new resource or existing)
  key_id = var.is_testing_mode && var.existing_key_id != "" ? var.existing_key_id : (local.create_key ? aws_kms_key.this[0].key_id : "")

  # Key ARN to use
  key_arn = var.is_testing_mode && var.existing_key_id != "" ? data.aws_kms_key.existing[0].arn : (local.create_key ? aws_kms_key.this[0].arn : "")
}

resource "aws_kms_key" "this" {
  count                   = local.create_key ? 1 : 0
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  customer_master_key_spec = var.customer_master_key_spec

  key_usage = "ENCRYPT_DECRYPT"
  policy                  = var.enable_default_policy ? data.aws_iam_policy_document.default[0].json : var.key_policy

  tags = merge(
    var.tags,
    {
      Name        = var.alias_name
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "this" {
  count         = local.create_key || (var.is_testing_mode && var.existing_key_id != "") ? 1 : 0
  name          = var.alias_name
  target_key_id = local.key_id
}

data "aws_iam_policy_document" "default" {
  count = var.enable_default_policy ? 1 : 0

  # Key administrators - can manage but not use the key
  statement {
    sid = "EnableIAMUserPermissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  # Key administrators
  statement {
    sid = "AllowAdminAccess"

    principals {
      type        = "AWS"
      identifiers = var.key_administrators
    }

    actions = [
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

    resources = ["*"]
  }

  # Key users
  statement {
    sid = "AllowKeyUsage"

    principals {
      type        = "AWS"
      identifiers = var.key_users
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # Allow EKS service role to use the key (if enabled)
  dynamic "statement" {
    for_each = var.attach_to_eks_role ? [1] : []
    content {
      sid = "AllowEKSClusterUse"

      principals {
        type        = "AWS"
        identifiers = [var.eks_cluster_role_name]
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = ["*"]
    }
  }

  # Allow autoscaling to use the key
  statement {
    sid = "AllowAutoscalingService"

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # Allow Secrets Manager to use the key
  dynamic "statement" {
    for_each = var.enable_secretsmanager_grants ? [1] : []
    content {
      sid = "AllowSecretsManagerUse"

      principals {
        type        = "Service"
        identifiers = ["secretsmanager.amazonaws.com"]
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ]

      resources = ["*"]
    }
  }
}

# Grant AWS services the ability to use the key for encryption/decryption
resource "aws_kms_grant" "s3" {
  count             = var.enable_s3_grants ? 1 : 0
  name              = "s3-${var.environment}"
  key_id            = local.key_id
  grantee_principal = "s3.amazonaws.com"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_grant" "rds" {
  count             = var.enable_rds_grants ? 1 : 0
  name              = "rds-${var.environment}"
  key_id            = local.key_id
  grantee_principal = "rds.amazonaws.com"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_grant" "ebs" {
  count             = var.enable_ebs_grants ? 1 : 0
  name              = "ebs-${var.environment}"
  key_id            = local.key_id
  grantee_principal = "ec2.amazonaws.com"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_grant" "efs" {
  count             = var.enable_efs_grants ? 1 : 0
  name              = "efs-${var.environment}"
  key_id            = local.key_id
  grantee_principal = "elasticfilesystem.amazonaws.com"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

data "aws_caller_identity" "current" {}
