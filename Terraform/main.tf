# 1 PROVIDER
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

# ---------- Network ----------

resource "aws_vpc" "main" {
  cidr_block         = var.vpc_cidr
  enable_dns_support = true


  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------- Security groups ----------

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App host: HTTP from anywhere, SSH from trusted IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "DB host: Postgres from app SG only, SSH from trusted IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# ---------- Compute ----------

# Latest Ubuntu 24.04 from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = var.app_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-app"
  }

  # don't replace the instance when a newer Ubuntu image is published
  lifecycle {
    ignore_changes = [ami]
  }
   credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = var.db_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-db"
  }

  lifecycle {
    ignore_changes = [ami]
  }

   credit_specification {
    cpu_credits = "standard"
  }
}

# ---------- Elastic IPs ----------
# Created once by hand and tagged, so they survive terraform destroy, will remove for final submission and use 
# public ips in outputs.tf

data "aws_eip" "app" {
  tags = {
    Name = "${var.project_name}-app-eip"
  }
}

data "aws_eip" "db" {
  tags = {
    Name = "${var.project_name}-db-eip"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = data.aws_eip.app.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_eip_association" "db" {
  instance_id   = aws_instance.db.id
  allocation_id = data.aws_eip.db.id
  depends_on    = [aws_internet_gateway.igw]
}
