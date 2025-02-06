provider "aws" {}

variable "cidr_block" {
    description ="cidr blocks and name tags for vpc and subnets"
    type = list(object({
      cidr_block = string
      name = string 
    }))

}

variable "enviroment" {
    description ="deployment enviroment"

}
variable "avail_zone" {
  
} #Envirmental Variable "export TF_VAR_avail_zone="us-east-1a" "

resource "aws_vpc" "dev-vpc" {
  cidr_block = var.cidr_block[0].cidr_block
  tags = {
    Name: var.cidr_block[0].name
  }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.cidr_block[1].cidr_block
    availability_zone = var.avail_zone
    tags = {
    Name: var.cidr_block[1].name
  }
}
