/*output "public_subnet_ids" {
  value = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
}

output "security_group_ids" {
  value = [aws_security_group.internal.id]
}
*/

output "subnet_ids" {
  value = [for subnet in aws_subnet.subnet: subnet.id]
}