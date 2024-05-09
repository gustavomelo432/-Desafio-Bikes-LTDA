terraform {
  required_version = ">=1.0.0" # Versão do Terraform

  # Provedores Utilizados
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0" # Versão do AWS no Terraform
    }
  }
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  token      = var.AWS_SESSION_TOKEN
}

variable "AWS_ACCESS_KEY_ID" {
  description = "The AWS access key ID"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "The AWS secret access key"
}

variable "AWS_SESSION_TOKEN" {
  description = "The AWS session token"
}

variable "AWS_REGION" {
  description = "The AWS region"
  default     = "us-east-1"  
}

# Criar grupo de segurança
resource "aws_security_group" "grupoefs" {
  name        = "grupefs"
  description = "Security group for EC2 instance"

  # Regra para permitir tráfego SSH na porta 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para permitir tráfego HTTP na porta 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para permitir tráfego TCP personalizado na porta 8080
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Habilitar saída para qualquer destino e porta
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "linux" {
  count                       = 2
  ami                         = "ami-0323c3dd2da7fb37d" # Amazon Linux 2
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.grupoefs.id]
  key_name                    = "vockey"                   # Certifique-se de ter a chave pública/privada para este nome!
  subnet_id                   = "subnet-066eaaa450821136a" # Sub-rede específica
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd git amazon-efs-utils

              sudo systemctl start httpd
              sudo systemctl enable httpd

              git clone https://github.com/FofuxoSibov/sitebike.git
              sudo mv sitebike/* /var/www/html/

              sudo mount -t efs -o tls ${aws_efs_file_system.efs.id}:/ /var/www/html/img
              EOF

  tags = {
    Name = "LinuxDesafio-${count.index + 1}"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "efs"
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = "subnet-066eaaa450821136a" # Sub-rede da VPC
  security_groups = [aws_security_group.grupoefs.id]
}
