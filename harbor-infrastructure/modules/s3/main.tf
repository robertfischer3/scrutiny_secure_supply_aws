module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = var.bucket_name
  acl    = var.bucket_acl

  # S2C2F compliance - Force private access
  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access

  # S2C2F compliance - Versioning for artifact integrity
  versioning = {
    enabled = var.versioning_enabled
    mfa_delete = var.versioning_mfa_delete
  }

  # S2C2F compliance - Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_master_key_id : null
      }
      bucket_key_enabled = var.bucket_key_enabled
    }
  }

  # S2C2F compliance - Object lifecycle rules
  lifecycle_rule = var.lifecycle_rule_enabled ? [
    {
      id      = "default"
      enabled = true
      
      # Optional expiration configuration
      expiration = var.lifecycle_expiration

      # Optional noncurrent version expiration
      noncurrent_version_expiration = var.lifecycle_noncurrent_version_expiration
      
      # Optional transitions to different storage classes
      transition = var.lifecycle_transitions
      
      # Optional noncurrent version transitions
      noncurrent_version_transition = var.lifecycle_noncurrent_version_transitions
    }
  ] : []

  # S2C2F compliance - Access logging
  logging = var.enable_access_logging ? {
    target_bucket = var.access_log_bucket_name
    target_prefix = var.access_log_prefix
  } : {}

  # S2C2F compliance - Object Lock for immutability
  object_lock_enabled = var.object_lock_enabled
  object_lock_configuration = var.object_lock_enabled ? {
    rule = {
      default_retention = {
        mode = var.object_lock_mode
        days = var.object_lock_days
        years = var.object_lock_years
      }
    }
  } : null

  # S2C2F compliance - Cross-region replication
  replication_configuration = var.enable_replication ? {
    role = aws_iam_role.replication[0].arn
    rules = [
      {
        id       = "harbor-artifacts-replication"
        status   = "Enabled"
        priority = 10

        # Source and destination configuration
        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = var.sse_algorithm == "aws:kms" ? true : false
          }
        }
        
        # Destination bucket
        destination = {
          bucket             = var.replication_destination_bucket_arn
          storage_class      = var.replication_storage_class
          replica_kms_key_id = var.replication_kms_key_id
          account_id         = var.replication_destination_account_id
          access_control_translation = var.replication_acl_translation ? {
            owner = "Destination"
          } : null
        }

        # Options for replication
        filter = {
          prefix = var.replication_prefix
          tags = var.replication_tags
        }
        
        delete_marker_replication_status = var.replication_delete_markers ? "Enabled" : "Disabled"
      }
    ]
  } : null

  # S2C2F compliance - CORS configuration if needed
  cors_rule = var.enable_cors ? var.cors_rule : []

  # S2C2F compliance - Intelligent tiering for cost optimization
  intelligent_tiering = {
    general = {
      status = var.intelligent_tiering_enabled ? "Enabled" : "Disabled"
      filter = {
        prefix = var.intelligent_tiering_prefix
        tags   = var.intelligent_tiering_tags
      }
      tiering = {
        archive_access_tier_days = var.intelligent_tiering_archive_days
        deep_archive_access_tier_days = var.intelligent_tiering_deep_archive_days
      }
    }
  }

  # Allow bucket to be destroyed even with content
  force_destroy = var.force_destroy

  # Attach additional policy to the bucket
  attach_policy = var.attach_policy
  policy        = var.attach_policy ? var.bucket_policy : null

  # Tags
  tags = var.tags
}

# S2C2F compliance - Default bucket policy to deny non-TLS access
resource "aws_s3_bucket_policy" "require_tls" {
  count  = var.require_tls && !var.attach_policy ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RequireTLSForAllRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# S2C2F compliance - IAM role for cross-region replication
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "s3-replication-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# S2C2F compliance - IAM policy for cross-region replication
resource "aws_iam_policy" "replication" {
  count       = var.enable_replication ? 1 : 0
  name        = "s3-replication-policy-${var.environment}"
  description = "Policy for S3 bucket replication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          module.s3_bucket.s3_bucket_arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${var.replication_destination_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect = "Allow"
        Resource = [
          var.kms_master_key_arn
        ]
        Condition = {
          StringLike = {
            "kms:ViaService"     = "s3.${var.aws_region}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" = [
              "${module.s3_bucket.s3_bucket_arn}/*"
            ]
          }
        }
      },
      {
        Action = [
          "kms:Encrypt"
        ]
        Effect = "Allow"
        Resource = [
          var.replication_kms_key_arn
        ]
        Condition = {
          StringLike = {
            "kms:ViaService"     = "s3.${var.replication_region}.amazonaws.com",
            "kms:EncryptionContext:aws:s3:arn" = [
              "${var.replication_destination_bucket_arn}/*"
            ]
          }
        }
      }
    ]
  })
}

# S2C2F compliance - Attach replication policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# S2C2F compliance - Event notifications for security events
resource "aws_s3_bucket_notification" "security_notifications" {
  count  = var.enable_security_notifications ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id

  dynamic "topic" {
    for_each = var.notification_topic_arn != "" ? [1] : []
    content {
      topic_arn     = var.notification_topic_arn
      events        = ["s3:ObjectRemoved:*", "s3:ObjectCreated:*"]
      filter_prefix = var.security_notification_prefix
    }
  }
  
  dynamic "lambda_function" {
    for_each = var.notification_lambda_function_arn != "" ? [1] : []
    content {
      lambda_function_arn = var.notification_lambda_function_arn
      events              = ["s3:ObjectRemoved:*", "s3:ObjectCreated:*"] 
      filter_prefix       = var.security_notification_prefix
    }
  }
}

# S2C2F compliance - Inventory configuration for asset tracking
resource "aws_s3_bucket_inventory" "inventory" {
  count  = var.enable_inventory ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id
  name   = "daily-inventory"

  included_object_versions = "All"
  
  schedule {
    frequency = "Daily"
  }
  
  destination {
    bucket {
      format     = "CSV"
      bucket_arn = var.inventory_destination_bucket_arn
      prefix     = var.inventory_destination_prefix
      account_id = var.inventory_destination_account_id
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier"
  ]
}

# S2C2F compliance - Ownership controls
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = module.s3_bucket.s3_bucket_id

  rule {
    object_ownership = var.object_ownership
  }
}