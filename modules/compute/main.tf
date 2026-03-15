# SSH KEY FOR BASTION HOST

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${var.ssh_key}.pem"
  file_permission = "0400"
}

# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR BASTION HOST

resource "aws_launch_template" "nexsecure_ec2" {
  name_prefix            = "nexsecure_ec2"
  instance_type          = var.instance_type
  image_id               = var.ami
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = var.ssh_key

  tags = {
    Name = "test"
  }
  
  //user_data = filebase64("${path.module}/example.sh")
}

resource "aws_autoscaling_group" "nexsecure_bastion" {
  name                = "nexsecure_bastion"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.nexsecure_ec2.id
    version = "$Latest"
  }
}


# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR FRONTEND APP TIER

resource "aws_launch_template" "nexsecure_app" {
  name_prefix            = "nexsecure_app"
  instance_type          = var.instance_type
  image_id               = var.ami
  vpc_security_group_ids = [var.frontend_app_sg]
  user_data              = filebase64("install_apache.sh")
  key_name               = var.ssh_key

  tags = {
    Name = "nexsecure_app"
  }
}

data "aws_lb_target_group" "nexsecure_tg" {
  name = var.lb_tg_name
}

resource "aws_autoscaling_group" "nexsecure_app" {
  name                = "nexsecure_app"
  vpc_zone_identifier = var.private_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  target_group_arns = [data.aws_lb_target_group.nexsecure_tg.arn]

  launch_template {
    id      = aws_launch_template.nexsecure_app.id
    version = "$Latest"
  }
}


# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR BACKEND

resource "aws_launch_template" "nexsecure_backend" {
  name_prefix            = "nexsecure_backend"
  instance_type          = var.instance_type
  image_id               = var.ami
  vpc_security_group_ids = [var.backend_app_sg]
  key_name               = var.ssh_key
  user_data              = filebase64("install_node.sh")

  tags = {
    Name = "nexsecure_backend"
  }
}

resource "aws_autoscaling_group" "nexsecure_backend" {
  name                = "nexsecure_backend"
  vpc_zone_identifier = var.private_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.nexsecure_backend.id
    version = "$Latest"
  }
}

# AUTOSCALING ATTACHMENT FOR APP TIER TO LOADBALANCER

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.nexsecure_app.name
  lb_target_group_arn    = var.lb_tg
}
