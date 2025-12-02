variable "env" {
  type    = string
  default = "poc"
}

variable "app_name" {
  type    = string
  default = "dr-demo"
}

# variable "account_id" {
#   type = string
# }

variable "db_master_username" {
  type    = string
  default = "admin"
}

variable "db_master_password" {
  type      = string
  sensitive = true
}
