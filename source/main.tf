provider "aws" {
  region = local.region
}

locals {
  region = "eu-west-1"
}

################################################################################
# VPC
################################################################################

/* module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "seera-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  manage_default_security_group = false
  default_security_group_name   = "seera-vpc-sg"
  enable_nat_gateway            = true
  single_nat_gateway            = true

  tags = {
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
} */

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "seera-vpc"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name        = "seera-public-subnet"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name        = "seera-private-subnet"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]


  tags = {
    Name        = "seera-db-subnet-group"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "seera-internet-gw"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_eip" "this" {
  vpc = true

  tags = {
    Name        = "seera-eip"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "seera-nat-gw"
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_security_group" "db_instance" {
  name        = "seera-database-sg"
  description = "Security group for mysql database"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    description = "database port"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_db_access"
  }
}
/*
###########################
# HTTP Security Group
###########################

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "seera-web-server-sg"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
}

###########################
# DB Security Group
###########################

module "database_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "seera-database-sg"
  description = "Security group for database"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "database ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
*/
###########################
# MySQL DB
###########################

resource "aws_db_instance" "this" {
  identifier             = "seera-db-instance"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "seeradb"
  username               = "user"
  password               = "passw0rd"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db_instance.id]
  publicly_accessible    = true
  port                   = "3306"
  availability_zone      = "eu-west-1a"
  multi_az               = false

  tags = {
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }
}
/*
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "seera-db"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  name     = "seera-db"
  username = "user"
  password = "p@ssw0rd!"
  port     = "3306"

  iam_database_authentication_enabled = true

  //vpc_security_group_ids = module.vpc.vpc_security_group_ids

  tags = {
    Owner       = "jonasdp"
    Terraform   = "true"
    Environment = "development"
    Consumer    = "seera"
  }

  # DB subnet group
  subnet_ids = module.vpc.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Disable database Deletion Protection
  deletion_protection = false

  # Disable creation of subnet group
  create_db_subnet_group = false

  # Disable creation of monitoring IAM role
  create_monitoring_role = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}
*/
