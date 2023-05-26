module "state_storage" {
  source = "./modules/terraform-backend"

  aws_kms_alias                       = "terraform-state-storage"
  tf_state_storage_bucket_name        = "terraform-state-storage"
  tf_state_storage_dynamodb_lock_name = "terraform-state-storage"
  aws_account_id                      = data.aws_caller_identity.current.account_id
}