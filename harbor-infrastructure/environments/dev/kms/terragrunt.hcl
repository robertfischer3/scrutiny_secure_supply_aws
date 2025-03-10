include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"

}

terraform {
  source = "../../../modules/kms"
}

inputs = {
  alias_name                   = "alias/harbor-keys-${include.env.inputs.environment}"
  description                  = "KMS key for Harbor encryption in ${include.env.inputs.environment}"
  deletion_window_in_days      = include.env.inputs.deletion_window_in_days
  enable_key_rotation          = true
  enable_default_policy        = true
  key_administrators           = ["arn:aws:iam::${include.env.inputs.aws_account_id}:role/Admin"]
  key_users                    = ["arn:aws:iam::${include.env.inputs.aws_account_id}:role/HarborKMSUser"]
  attach_to_eks_role           = false  # Will be updated after EKS is created
  is_testing_mode              = include.env.inputs.is_testing_mode
  create_new_key               = include.env.inputs.create_new_key
  reuse_existing_key_prefix    = include.env.inputs.reuse_existing_key_prefix
  key_usage                    = include.env.inputs.key_usage
  enable_key_rotation          = include.env.inputs.enable_key_rotation
  customer_master_key_spec     = "SYMMETRIC_DEFAULT"

}