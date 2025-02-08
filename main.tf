provider "aws" {}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}

variable "avail_zone" {} #Envirmental Variable "export TF_VAR_avail_zone="us-east-1a" "
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}
variable "private_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"   #string interpolation
  }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
  
}

# Modify the default route table
# resource "aws_default_route_table" "myapp-main-rtb" {
#   default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name: "${var.env_prefix}-main-rtb"
#   }
# }

resource "aws_security_group" "myapp-sg" {  #you can use the deffault sg for the vpc "resource "aws_default_security_group" "

  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22 
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip] #list of ip addresses to access the security group
  }
  ingress {
    from_port = 8080 
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #list of ip addresses to access the security group (Everyone)
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"] 
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  } 
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key-myapp" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
  
}
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true

  key_name = aws_key_pair.ssh-key-myapp.key_name

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }


# Provisioners are not recommended in terraform it is the last resort when your really need it. this is because
# Provisioners do not really work well
# Provisioners breaks the "idempotency" concept of terraform
# in place of provisioners you can use other configuration management tools (Ansible,puppet,chef e.t.c)
  provisioner "file" { #to copy local file to remote ec2 instance
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"

    #you can add a connction block if you want to copy a file to another instance
  }
  provisioner "remote-exec" {
    
      script = file("entry-script-on-ec2.sh")  
    
  }

  provisioner "local-exec" { # use to execute commands on your local machine
    command = "echo ${self.public_ip} > output.txt"
    
  }
  
  tags = {
    Name = "${var.env_prefix}-server"
  } 

  
}

