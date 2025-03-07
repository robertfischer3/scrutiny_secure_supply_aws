include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name          = "harbor-artifacts-${local.environment}-${get_aws_account_id()}"
  force_destroy        = local.environment != "prod"
  versioning_enabled   = true
  sse_algorithm        = "aws:kms"
  kms_master_key_id    = dependency.kms.outputs.key_arn
  block_public_access  = true
  lifecycle_rule = {
    enabled = true
    expiration = {
      days = local.environment == "prod" ? 0 : 90  # 0 means never expire in prod
    }
    noncurrent_version_expiration = {
      days = local.environment == "prod" ? 365 : 30
    }
  }
  cors_rule = {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["https://${local.harbor_domain}"]
    max_age_seconds = 3000
  }
}

dependency "kms" {
  config_path = "../kms"
}