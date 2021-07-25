################################################################################
# Providers
################################################################################

provider "aws" {
  region = var.region
}

################################################################################
# Networking
################################################################################

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = merge({ Name = "${var.project}-vpc" }, extra_tags)
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "eu-west-1a"

  tags = merge({ Name = "${var.project}-public" }, extra_tags)
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = merge({ Name = "${var.project}-private-1" }, extra_tags)
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = merge({ Name = "${var.project}-private-2" }, extra_tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge({ Name = "${var.project}-igw" }, extra_tags)
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id

  tags = merge({ Name = "${var.project}-nat" }, extra_tags)

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "this" {
  vpc = true

  tags = merge({ Name = "${var.project}-eip" }, extra_tags)
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  tags = merge({ Name = "${var.project}-private" }, extra_tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge({ Name = "${var.project}-public" }, extra_tags)
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id

  subnet_id = aws_subnet.public.id
}

resource "aws_route_table_association" "private_1" {
  route_table_id = aws_route_table.private.id

  subnet_id = aws_subnet.private_1.id
}

resource "aws_route_table_association" "private_2" {
  route_table_id = aws_route_table.private.id

  subnet_id = aws_subnet.private_2.id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-subnetgroup"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = merge({ Name = "${var.project}-subnetgroup" }, extra_tags)
}

###########################
# EC2 Security Group
###########################

resource "aws_security_group" "ec2_instance" {
  name        = "${var.project}-ec2-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.this.id

  tags = merge({ Name = "${var.project}-ec2-sg" }, extra_tags)

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###########################
# DB Security Group
###########################

resource "aws_security_group" "db_instance" {
  name        = "${var.project}-db-sg"
  description = "Security group for mysql database"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    description     = "database port"
    security_groups = ["${aws_security_group.ec2_instance.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.project}-db-sg" }, extra_tags)
}

###########################
# MySQL DB
###########################

resource "aws_db_instance" "this" {
  identifier             = "${var.project}-db-instance"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = var.db_name
  username               = var.db_user
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db_instance.id]

  tags = merge({ Name = "${var.project}-db-instance" }, extra_tags)
}

###########################
# SSH keys
###########################

resource "aws_key_pair" "this" {
  key_name   = "${var.project}-keypair"
  public_key = file(var.ssh_public_key)
}
