include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/kms"
}

inputs = {
  alias_name                   = "alias/harbor-keys-${local.environment}"
  description                  = "KMS key for Harbor encryption in ${local.environment}"
  deletion_window_in_days      = 30
  enable_key_rotation          = true
  enable_default_policy        = true
  key_administrators           = ["arn:aws:iam::${get_aws_account_id()}:role/Admin"]
  key_users                    = ["arn:aws:iam::${get_aws_account_id()}:role/HarborKMSUser"]
  attach_to_eks_role           = true
  eks_cluster_role_name        = dependency.eks.outputs.cluster_iam_role_name
  enable_secretsmanager_grants = true
}

dependency "eks" {
  config_path = "../eks"
}