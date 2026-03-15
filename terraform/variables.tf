variable "ssh_key" {
  type = string
}
variable "access_ip" {
  type = string
}

variable "db_name" {
  type = string
}

variable "ami" {
  type = string
}

variable "dbuser" {
  type      = string
  sensitive = true
}

variable "dbpassword" {
  type      = string
  sensitive = true
}

variable "instance_type" {
  type = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "github_repo" {
  description = "GitHub repository allowed to assume this role"
  type        = string
}

