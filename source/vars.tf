variable "aws_region" {
  description = "The aws region to use"
  default     = "eu-west-1"
  type        = string
}

variable "project_name" {
  description = "The project name"
  default     = "terraform"
}

variable "db_name" {
  description = "db name"
}

variable "db_user" {
  description = "DB username"
}

variable "db_password" {
  description = "DB password"
}


variable "ssh_public_key" {
  description = "Public key for ec2 instance"
}

variable "ssh_private_key" {
  description = "Private key for ec2 instance"
}
