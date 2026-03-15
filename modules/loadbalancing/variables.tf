variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}

variable "lb_sg" {
  description = "Load balancer security group"
  type        = string
}

variable "tg_port" {
  description = "Target group port"
  type        = number
  default     = 80
}

variable "tg_protocol" {
  description = "Target group protocol"
  type        = string
  default     = "HTTP"
}

variable "listener_port" {
  description = "Listener port"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Listener protocol"
  type        = string
  default     = "HTTP"
}

# variable "app_asg" {
#   description = "Auto Scaling Group name"
#   type        = string
# }
