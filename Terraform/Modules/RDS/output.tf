output "database_host" {
  value = aws_db_instance.rds.address
}

output "database_name" {
  value = var.database_name
}

output "database_username" {
  value = var.database_username
} 

output "database_instance_id" {
  value = aws_db_instance.rds.identifier
}
