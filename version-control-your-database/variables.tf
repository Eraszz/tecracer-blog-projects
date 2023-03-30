variable "master_password" {
  type        = string
  description = "Password for the RDS database"
  sensitive = true
  default     = "supersecretpassword"
}

variable "master_username" {
  type        = string
  description = "Username for the RDS database"
  sensitive = true
  default     = "admin"
}

variable "flyway_version" {
  type        = string
  description = "Flyway version to use"
  default     = "7.15.0"
}

variable "flyway_conf" {
  type        = string
  description = "Name of the Flyway config file"
  default     = "test_flyway.conf"
}

variable "flyway_managed_databases" {
  type        = list(string)
  description = "List of databases that should be managed by Flyway"
  default     = ["Users", "Products"]
}