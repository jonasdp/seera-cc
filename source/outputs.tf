output "db_access_ec2" {
  value = "mysql -h ${aws_db_instance.this.address} -P ${aws_db_instance.this.port} -u ${var.db_user} -p ${var.db_name}"
}

output "ssh_access" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${aws_instance.this.public_ip}"
}

output "web_access" {
  value = "http://${aws_instance.this.public_ip}/seera"
}
