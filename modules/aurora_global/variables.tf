variable "global_cluster_identifier" {
  type = string
}

variable "kms_key_arn_primary" {
  type = string
}

variable "kms_key_arn_dr" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "db_subnet_group_name_primary" {
  type = string
}

variable "db_subnet_group_name_dr" {
  type = string
}

variable "vpc_security_group_ids_primary" {
  type = list(string)
}

variable "vpc_security_group_ids_dr" {
  type = list(string)
}
