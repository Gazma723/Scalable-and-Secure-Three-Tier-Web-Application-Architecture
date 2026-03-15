output "app_asg" {
  value = aws_autoscaling_group.nexsecure_app
}

output "app_backend_asg" {
  value = aws_autoscaling_group.nexsecure_backend
}
