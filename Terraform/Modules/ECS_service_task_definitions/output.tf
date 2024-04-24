output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_tasks_sg" {
  value = aws_security_group.ecs_tasks
}