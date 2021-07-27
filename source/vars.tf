variable "aws_region" {
  description = "The aws region to use"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
}

variable "db_name" {
  description = "db name"
  type        = string
}

variable "db_user" {
  description = "DB username"
  type        = string
}

variable "db_password" {
  description = "DB password"
  type        = string
}

variable "ssh_public_key" {
  description = "Public key for ec2 instance"
  type        = string
}

variable "ssh_private_key" {
  description = "Private key for ec2 instance"
  type        = string
}

variable "extra_tags" {
  description = "The tags to use for resources"
  type        = map(string)
}
