output "db_access" {
  description = "Command to login to the DB and only works from the EC2 instance"
  value       = "mysql -h ${aws_db_instance.this.address} -P ${aws_db_instance.this.port} -u ${var.db_user} -p ${var.db_name}"
}

output "ssh_access" {
  description = "Command to login to the EC2 instance"
  value       = "ssh -i ${var.ssh_private_key} ubuntu@${aws_instance.this.public_ip}"
}

output "web_access" {
  description = "URL to the wordpress site"
  value       = "http://${aws_instance.this.public_ip}/${var.project_name}"
}
