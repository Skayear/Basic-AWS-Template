#terraform import aws_subnet.mi_subred subnet-01201c0141c46258e

# import {
#   to = aws_subnet.mi_subred
#   id = "subnet-01201c0141c46258e"
# }

# resource "aws_subnet" "mi_subred" {
#   id                  = "subnet-01201c0141c46258e"  # Este valor debe coincidir con el ID de la subred importada
#   vpc_id              = "vpc-0066dfff23fb226b5"     # Cambia esto al ID de tu VPC
#   cidr_block          = "10.0.1.0/24"  # Ajusta el bloque CIDR según tu subred existente
#   availability_zone   = "us-east-1"  # Cambia esto según tu zona de disponibilidad
# }

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

##########################
## Public subnet routing
##########################
resource "aws_route_table" "route_table" {
  count = var.privacy == "public" ? 1 : 0

  vpc_id = var.vpc_id

  tags = {
  Name = format("%s-%s-%s-rt", var.subnet_name,element([for subnet in var.subnet_list: subnet.az], count.index),var.env_name)
  }
}

resource "aws_route" "route" {
  count = var.privacy == "public" ? 1 : 0

  route_table_id         = aws_route_table.route_table.0.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id

  depends_on = [
    aws_route_table.route_table
  ]
}

resource "aws_route_table_association" "route_table_association" {
  for_each = var.privacy == "public" ?  aws_subnet.subnet : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table.0.id

  depends_on = [
    aws_route_table.route_table
  ]
}