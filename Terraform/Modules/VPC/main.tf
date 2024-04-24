/*====
The VPC
======*/  
resource "aws_vpc" "vpc" {
   cidr_block = var.vpc_cdir_block
   enable_dns_support = true
   enable_dns_hostnames = true
  tags = {
    Name = format("%s-%s",  var.vpc_name,var.env_name )  
  }
} 
 
resource "aws_internet_gateway" "IGW" {  
  vpc_id = aws_vpc.vpc.id
}
 