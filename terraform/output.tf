
output "load_balancer_endpoint" {
  value = module.loadbalancing.lb_endpoint
}

output "database_endpoint" {
  value = module.database.db_endpoint
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}

