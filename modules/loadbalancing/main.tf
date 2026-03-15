

# INTERNET FACING LOAD BALANCER

resource "aws_lb" "nexsecure_lb" {
  name               = "nexsecure-loadbalancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.lb_sg]
  subnets         = var.public_subnets

  idle_timeout = 400

  tags = {
    Name        = "nexsecure-alb"
    Environment = "production"
  }
}


resource "aws_lb_target_group" "nexsecure_tg" {
  name     = "nexsecure-lb-tg"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "nexsecure-target-group"
  }
}



resource "aws_lb_listener" "nexsecure_lb_listener" {
  load_balancer_arn = aws_lb.nexsecure_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexsecure_tg.arn
  }

  tags = {
    Name = "nexsecure-listener"
  }
}


