# Define your AWS provider configuration
provider "aws" {
  region  = "us-west-1" # Replace with your desired AWS region
  profile = "myprofile" # Specify your AWS CLI profile name here
}

# Create a VPC
resource "aws_vpc" "ayo_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
  tags = {
    Name = "ayoVpc"
  }
}

# Create subnets within the VPC
resource "aws_subnet" "ayo_subnet" {
  vpc_id                  = aws_vpc.ayo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a" # Replace with your desired AZ
  map_public_ip_on_launch = true         # This makes it a public subnet
  tags = {
    Name = "ayoSubnet"
  }
}

resource "aws_subnet" "ayo_subnet_az1" {
  vpc_id                  = aws_vpc.ayo_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ayoSubnetAZ1"
  }
}

resource "aws_subnet" "ayo_subnet_az2" {
  vpc_id                  = aws_vpc.ayo_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "ayoSubnetAZ2"
  }
}


resource "aws_db_subnet_group" "ayo_db_subnet_group" {
  name = "ayo-db-subnet-group"
  subnet_ids = [
    aws_subnet.ayo_subnet.id,
    aws_subnet.ayo_subnet_az1.id,
    aws_subnet.ayo_subnet_az2.id,
  ]

  description = "My DB Subnet Group"
}


# Create an RDS database instance
resource "aws_db_instance" "ayo_db" {
  allocated_storage   = 20
  db_name             = "ayodb"
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t2.micro"
  username            = "ayomide"
  password            = "mypassword"
  skip_final_snapshot = true # Don't create a final DB snapshot when deleting

  # Associate the RDS instance with the private subnet
  db_subnet_group_name = aws_db_subnet_group.ayo_db_subnet_group.name

  tags = {
    Name = "ayo-rds-instance"
  }
}

# Create three EC2 instances and associate them with the public subnet
resource "aws_instance" "ayo_instances" {
  count         = 3
  ami           = "ami-0f8e81a3da6e2510a" # Ubuntu 20.04 LTS AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ayo_subnet.id # Associate with the public subnet
  key_name      = "ayoterraformkey"        # Replace with the name of your EC2 key pair

  # Additional EC2 instance configuration, e.g., user data, tags, etc.

  tags = {
    Name = "ayotf-ec2-instance-${count.index}"
  }

  ## installing packages on the instance
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install nginx -y
  sudo systemctl start nginx
  sudo systemctl enable nginx
  sudo apt install npm -y
  EOF
}
