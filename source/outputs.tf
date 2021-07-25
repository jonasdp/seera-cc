output "db_access" {
  value = "mysql -h ${aws_db_instance.this.address} -P ${aws_db_instance.this.port} -u ${var.db_user} -p${var.db_password}"
}
