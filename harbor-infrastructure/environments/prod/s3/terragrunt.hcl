include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

# Module-specific inputs will be defined here

# Dependencies will be defined here if needed
