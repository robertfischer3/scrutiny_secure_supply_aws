include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/s3-notifications"
}

dependency "s3" {
  config_path = "../s3"
  skip_outputs = false
}

dependency "sns" {
  config_path = "../sns"
  skip_outputs = false
}

inputs = {
  bucket_id           = dependency.s3.outputs.s3_bucket_id
  topic_arn           = dependency.sns.outputs.topic_arn
  topic_name          = dependency.sns.outputs.topic_name
  events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  filter_prefix       = "registry/"
  update_sns_policy   = true
}

dependencies {
  paths = ["../s3", "../sns"]
}