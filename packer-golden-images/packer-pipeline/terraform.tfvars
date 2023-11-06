application_name                    = "packer-ami-build-pipeline"
sns_endpoint                        = "hhagen@tecracer.de"
account_ids = {
    dev = "843934227598"
    prd = "850854358454"
} 

tf_state_aws_kms_alias              = "terraform-state-storage"
tf_state_storage_bucket_name        = "terraform-state-storage"
tf_state_storage_dynamodb_lock_name = "terraform-state-storage"