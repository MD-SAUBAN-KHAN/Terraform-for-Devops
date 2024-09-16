provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "keypair" {
  key_name   = "terra-key"
  public_key = file("/mnt/c/MDSK-DevOps/.ssh/terraform_rsa.pub")
}

resource "aws_vpc" "vpc2" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gateway2" {
  vpc_id = aws_vpc.vpc2.id
}

resource "aws_route_table" "routetable2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway2.id
  }
}

resource "aws_route_table_association" "table-asso2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable2.id
}

resource "aws_security_group" "web2" {
  name   = "web2"
  vpc_id = aws_vpc.vpc2.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web2"
  }
}

resource "aws_instance" "test-3" {
  tags = {
    name                      = "test-3"
  } 
  ami                         = var.ami_value
  instance_type               = var.instance_type_value
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.web2.id]
  subnet_id                   = aws_subnet.subnet2.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/tmp/terraform_rsa")
    host        = self.public_ip
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "/mnt/c/MDSK-DevOps/missile/missile/home.html"
    destination = "/home/ubuntu/home.html"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Remote instance is now in EXECUTION'",
      "sudo apt update -y",
     # "sudo apt install xdg-utils",
      #"cd /mnt/c/MDSK-DevOps/missile/missile",
      #"explorer.exe home.html",
    ]
  }
}

resource "aws_s3_bucket" "state_bucket2" {
  bucket = "terra-state-mdsk"
}

resource "aws_dynamodb_table" "terraform_lock" {
  name                        = "terraform-lock"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "LockID"
  deletion_protection_enabled = "false"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table"
    Environment = "dev"
  }
}
