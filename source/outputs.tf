output "db_access" {
  description = "Command to login to the DB and only works from the EC2 instance"
  value       = "mysql -h ${aws_db_instance.mysql.address} -P ${aws_db_instance.mysql.port} -u ${var.db_user} -p ${var.db_name}"
}

output "ssh_access" {
  description = "Command to login to the EC2 instance"
  value       = "ssh -i ${var.ssh_private_key} ubuntu@${aws_instance.ec2.public_ip}"
}

output "web_access" {
  description = "URL to the wordpress site"
  value       = "http://${aws_instance.ec2.public_ip}/${var.project_name}"
}
