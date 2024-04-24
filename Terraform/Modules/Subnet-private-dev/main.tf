
resource "aws_subnet" "subnet" {
  for_each = {for i, v in var.subnet_list:  i => v}

  vpc_id     = var.vpc_id
  cidr_block = each.value.cidr_block
  availability_zone =  format("%s%s", var.region,each.value.az) 

  map_public_ip_on_launch = var.privacy == "public" ? true : false

  tags = {
    Name = format("%s-%s-%s", var.subnet_name,each.value.az,var.env_name) 
  }
}

# ###########################
# ## Private Subnet routing
# ###########################
resource "aws_eip" "eip" {
  #for_each = var.privacy == "private" ? aws_subnet.subnet : {} 
 
  vpc = true
 
}
 
resource "aws_nat_gateway" "nat" {
  #count = var.privacy == "private" ? length(aws_subnet.subnet) : 0

  #allocation_id = element([for eip in aws_eip.eip : eip.id], count.index)
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_nat_subnet.0.id

  tags = {
    Name = format("%s-%s-nat", var.subnet_name, var.env_name) 
  } 
 
}

resource "aws_route_table" "private_route_table" {
  count = var.privacy == "private" ? length(aws_subnet.subnet) : 0

  vpc_id = var.vpc_id

   tags = {
    Name = format("%s-%s-%s-rt", var.subnet_name,element([for subnet in var.subnet_list: subnet.az], count.index),var.env_name) 
  }
}
 
resource "aws_route" "private_route" {
  count = var.privacy == "private" ? length(aws_subnet.subnet) : 0 
 
  route_table_id         = element([for route_table in aws_route_table.private_route_table : route_table.id], count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
 
resource "aws_route_table_association" "private_route_table_association" {
  count =  var.privacy == "private" ? length(aws_subnet.subnet) : 0 

  subnet_id      = element([for subnet in aws_subnet.subnet : subnet.id], count.index)
  route_table_id = element([for route_table  in aws_route_table.private_route_table : route_table .id], count.index)
}

resource "aws_subnet" "public_nat_subnet" {
  count = var.privacy == "private" ? 1 : 0
 
  vpc_id     = var.vpc_id
  cidr_block = "10.2.7.0/24"
  availability_zone =  format("%s%s", var.region,"a") 

  map_public_ip_on_launch = true 

  tags = {
    Name = format("%s-%s-%s-nat", var.subnet_name,"a",var.env_name) 
  }
}
 
resource "aws_route_table" "nat_public_route_table" {
  count = var.privacy == "private" ? 1 : 0

  vpc_id = var.vpc_id

  tags = {
  Name = format("%s-%s-%s-rt-NAT", var.subnet_name,element([for subnet in var.subnet_list: subnet.az], count.index),var.env_name) 
  }
}
 
resource "aws_route" "nat_public_route" {
  count = var.privacy == "private" ? 1 : 0 
 
  route_table_id         = aws_route_table.nat_public_route_table.0.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id         = var.igw_id
}
 
resource "aws_route_table_association" "nat_public_route_table_association" {
  count =  var.privacy == "private" ? 1 : 0 
 
  subnet_id      = aws_subnet.public_nat_subnet.0.id
  route_table_id = aws_route_table.nat_public_route_table.0.id
 
}