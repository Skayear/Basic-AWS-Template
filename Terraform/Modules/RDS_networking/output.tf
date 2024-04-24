
output "database_sg_id" {
  value = aws_security_group.db_access_sg.id
}

output "subnet_group_id" {
  value = aws_db_subnet_group.rds_subnet_group.id
}

output "security_group_ids" {
  value = aws_security_group.rds_sg.id
}

output "subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}