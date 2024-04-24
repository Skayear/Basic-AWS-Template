/* subnet used by rds */
resource "aws_db_subnet_group" "rds_subnet_group" {

  name        = "rds-subnet-group-${var.env_full_name}"
  description = "rds subnet group"

  subnet_ids = var.subnet_ids

  tags = {
    Environment = var.env_name
  }
}
 
resource "aws_security_group" "rds_sg" {
  name        = "${var.env_full_name}-rds-sg"
  description = "${var.env_full_name} Security Group"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${var.env_full_name}-rds-sg"
    Environment = var.env_name
  }

  //Allow access from DBP vpn
  ingress {
    description = "Allow access from devs"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // allows traffic from the SG itself
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  //allow traffic for TCP 5432
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.db_access_sg.id]
  }

  // outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* Security Group for resources that want to access the Database */
resource "aws_security_group" "db_access_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.env_full_name}-db-access-sg"
  description = "Allow access to RDS"

  tags = {
    Name        = "${var.env_full_name}-db-access-sg"
    Environment = var.env_name
  }

} 