variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type    = number
  default = 2
}

variable "vpc_name" {
    type = string
    default = "jzbx-app"
}
