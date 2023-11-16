application_name                    = "packer-ami-build-pipeline"
sns_endpoint                        = "test@example.com"
account_ids = {
    dev = "xxxxx"
    prd = "xxxxx"
} 

tf_state_aws_kms_alias              = "terraform-state-storage"
tf_state_storage_bucket_name        = "terraform-state-storage"
tf_state_storage_dynamodb_lock_name = "terraform-state-storage"