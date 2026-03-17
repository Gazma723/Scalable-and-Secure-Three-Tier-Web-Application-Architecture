variable "ssh_key" {
  type = string
  default = "devamuleya"
}
variable "access_ip" {
  type = string
  default = "0.0.0.0/0"
}

variable "db_name" {
  type = string
  default = "nexsecure_db"
}

variable "ami" {
  type = string
  default = "ami-02dfbd4ff395f2a1b"
}

variable "dbuser" {
  type      = string
  sensitive = true
  default = "nexsecure_user"
}

variable "dbpassword" {
  type      = string
  sensitive = true
  default = "devamuleya123"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default = [ "us-east-1a",
  "us-east-1b",
  "us-east-1c" ]
}

variable "github_repo" {
  description = "GitHub repository allowed to assume this role"
  type        = string
}

