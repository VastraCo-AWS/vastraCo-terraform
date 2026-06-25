output "db_endpoint" {
  description = "RDS instance endpoint (hostname only)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "PostgreSQL master username"
  value       = aws_db_instance.main.username
}

output "db_password" {
  description = "PostgreSQL master password (sensitive)"
  value       = random_password.db.result
  sensitive   = true
}

output "rds_security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}
