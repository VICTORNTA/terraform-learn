provider "aws"{}



resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"   #string interpolation
  }
}
module "my_app_subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}


module "myapp-server" {
  source = "./modules/webserver"
   vpc_id = aws_vpc.myapp-vpc.id
   my_ip = var.my_ip
   env_prefix = var.env_prefix
   image_name = var.image_name
   public_key_location = var.public_key_location
   subnet_id = module.my_app_subnet.subnet.id
   instance_type = var.instance_type
   avail_zone = var.avail_zone
  
}

