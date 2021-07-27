###############################################################################
# Providers
###############################################################################

provider "aws" {
  region = var.aws_region
}

###############################################################################
# Loccal variables
###############################################################################
locals {
  alpha_project_name = replace(var.project_name, "/[^a-zA-Z0-9]/", "")
}

###############################################################################
# Networking
###############################################################################

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = merge({ Name = "${var.project_name}-vpc" }, var.extra_tags)
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "eu-west-1a"

  tags = merge({ Name = "${var.project_name}-public" }, var.extra_tags)
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = merge({ Name = "${var.project_name}-private-1" }, var.extra_tags)
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = merge({ Name = "${var.project_name}-private-2" }, var.extra_tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge({ Name = "${var.project_name}-igw" }, var.extra_tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge({ Name = "${var.project_name}-public" }, var.extra_tags)
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id

  subnet_id = aws_subnet.public.id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-subnetgroup"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = merge({ Name = "${var.project_name}-subnetgroup" }, var.extra_tags)
}

######################################################
# EC2 Security Group
######################################################

resource "aws_security_group" "ec2_instance" {
  name        = "${var.project_name}-ec2-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.this.id

  tags = merge({ Name = "${var.project_name}-ec2-sg" }, var.extra_tags)

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

######################################################
# DB Security Group
######################################################

resource "aws_security_group" "db_instance" {
  name        = "${var.project_name}-db-sg"
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

  tags = merge({ Name = "${var.project_name}-db-sg" }, var.extra_tags)
}

######################################################
# MySQL DB
######################################################

resource "aws_db_instance" "mysql" {
  identifier             = "${var.project_name}-db-instance"
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

  tags = merge({ Name = "${var.project_name}-db-instance" }, var.extra_tags)
}

######################################################
# SSH keys
######################################################

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-keypair"
  public_key = file(var.ssh_public_key)
}

######################################################
# Config files that WP need
######################################################

data "template_file" "phpconfig" {
  template = file("wp-provision/wp-config.php")

  vars = {
    db_port = aws_db_instance.mysql.port
    db_host = aws_db_instance.mysql.address
    db_user = var.db_user
    db_pass = var.db_password
    db_name = var.db_name
  }
}

data "template_file" "apacheconfig" {
  template = file("wp-provision/apache.conf")

  vars = {
    url_alias = var.project_name
  }
}

######################################################
# The EC2 instance for WP
######################################################

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_instance.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  user_data = file("wp-provision/wp-provision.sh")

  tags = merge({ Name = "${var.project_name}-ec2-instance" }, var.extra_tags)

  depends_on = [
    aws_db_instance.mysql
  ]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-groovy-20.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

######################################################
# Lookup the current AWS partition
######################################################
data "aws_partition" "current" {
}

######################################################
# Cloudwatch alarm that auto_recover the instance if the system status check fails for two minutes
######################################################
resource "aws_cloudwatch_metric_alarm" "auto_recover" {
  alarm_name          = "${var.project_name}-${aws_instance.ec2.id}-StatusCheckFailed"
  metric_name         = "StatusCheckFailed_System"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"

  dimensions = {
    InstanceId = aws_instance.ec2.id
  }

  namespace         = "AWS/EC2"
  period            = "60"
  statistic         = "Minimum"
  threshold         = "0"
  alarm_description = "Cloudwatch alarm that auto-recovers the instance if the system status check fails for two minutes"
  alarm_actions = compact(
    [
      "arn:${data.aws_partition.current.partition}:automate:${var.aws_region}:ec2:recover",
    ]
  )

  depends_on = [
    aws_instance.ec2
  ]
}

######################################################
# To make sure the ec2 is running and finsihed the apt installs
######################################################
resource "time_sleep" "wait_60_seconds" {
  depends_on = [aws_instance.ec2]

  create_duration = "60s"
}

######################################################
# Configuring and setting up WP
######################################################
resource "null_resource" "congifure_ec2" {
  triggers = {
    public_ip = aws_instance.ec2.public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    agent       = false
    host        = aws_instance.ec2.public_ip
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    content     = data.template_file.apacheconfig.rendered
    destination = "/tmp/apache.conf"
  }

  provisioner "file" {
    content     = data.template_file.phpconfig.rendered
    destination = "/tmp/wp-config.php"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/wp-config.php /etc/wordpress/config-${aws_instance.ec2.public_ip}.php",
      "sudo cp /tmp/apache.conf /etc/apache2/sites-available/wordpress.conf",
      "sudo a2ensite wordpress",
      "sudo a2enmod rewrite",
      "sudo service apache2 reload"
    ]
  }

  depends_on = [
    time_sleep.wait_60_seconds
  ]
}
