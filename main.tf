terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

output "ec2_id" {
  value = aws_instance.self.id
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_iam_role" "self" {
  name = uuid()
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "aws_iam_policy_attachment" "self" {
  name       = uuid()
  roles      = [aws_iam_role.self.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "aws_iam_instance_profile" "self" {
  name = "deploy_test"
  role = aws_iam_role.self.name
}

resource "aws_security_group" "self" {
  name   = uuid()
  vpc_id = var.aws_vpc_id

  ingress = [
    {
      description      = ""
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  egress = [
    {
      description      = ""
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]

  tags = {
    Name = "deploy_test"
  }

  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

resource "aws_instance" "self" {
  ami                    = "ami-074d4d6a02df638da"
  instance_type          = "t3.micro"
  subnet_id              = var.aws_subnet_id
  vpc_security_group_ids = [aws_security_group.self.id]
  iam_instance_profile   = aws_iam_instance_profile.self.name
}
