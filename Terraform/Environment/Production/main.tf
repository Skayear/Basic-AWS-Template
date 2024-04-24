locals {

  # count = var.create_environment ? 1 : 0
  
  application_name = var.application_name
  prefix           = var.prefix
  environment      = var.environment

  availability_zones = ["${var.region}a", "${var.region}b"]
  env_full_name      = "${local.prefix}-${local.application_name}-${local.environment}"

  vpc_name       = "${local.prefix}-${local.application_name}-VPC"
  vpc_cdir_block = "10.0.0.0/16"

  public_subnet_name = "Public ECS SubNet"
  public_subnet_list = [{
    az         = "a"
    cidr_block = "10.0.1.0/24"
    },
    {
      az         = "b"
      cidr_block = "10.0.2.0/24"
  }]

  # private_subnet_name = "Private ECS SubNet"
  # private_subnet_list = [{
  #   az         = "a"
  #   cidr_block = "10.0.3.0/24"
  #   },
  #   {
  #     az         = "b"
  #     cidr_block = "10.0.4.0/24"
  # }]

  # isolated_subnet_name = "Isolated DBs SubNet"
  # isolated_subnet_list = [{
  #   az         = "a"
  #   cidr_block = "10.0.5.0/24"
  #   },
  #   {
  #     az         = "b"
  #     cidr_block = "10.0.6.0/24"
  # }]

}

# module "private_subnets" {
#   source = "../../Modules/Subnet"

 
#   env_name = var.environment 
#   region = var.region

#   vpc_id = module.VPC.vpc_id
#   igw_id = module.VPC.igw_id

#   subnet_name = local.private_subnet_name  
#   subnet_list = local.private_subnet_list
#   privacy = "private"

# }

module "public_subnets" {
  source = "../../Modules/Subnet"
 
  env_name = var.environment 
  region = var.region

  vpc_id = module.VPC.vpc_id
  igw_id = module.VPC.igw_id
  
  subnet_name = local.public_subnet_name
  subnet_list = local.public_subnet_list 
  privacy = "public"

}

# module "isolated_subnets" {
#   source = "../../Modules/Subnet"
 
#   env_name = var.environment 
#   region = var.region

#   vpc_id = module.VPC.vpc_id 
#   igw_id = module.VPC.igw_id
  
#   subnet_name = local.isolated_subnet_name
#   subnet_list = local.isolated_subnet_list 
#   privacy = "isolated"

# }

module "RDS_networking" {
  source = "../../Modules/RDS_networking"
    
  env_name = var.environment
  vpc_id =  module.VPC.vpc_id 
  env_full_name = local.env_full_name 
  subnet_ids              = module.public_subnets.subnet_ids
}

# module "RDS" {
#   source = "../../Modules/RDS"

#   identifier              = "${local.prefix}-${local.application_name}-db-${local.environment}"
#   allocated_storage       = "20"
#   engine                  = "postgres"
#   engine_version          = "13.13"
#   instance_class          = "db.t4g.micro"
#   multi_az                = false
#   database_name           = "glovender_database"
#   database_username       = "admin" 
#   subnet_ids              = module.public_subnets.subnet_ids
#   subnet_group_id         = module.RDS_networking.subnet_group_id
#   security_group_ids      = module.RDS_networking.security_group_ids
#   deletion_protection     = false
#   apply_immediately       = true
#   storage_encrypted       = false
#   monitoring_interval     = 0
#   env_name                = var.environment
#   publicly_accessible     = true
# }

# module "ecr" {
#   source = "../../Modules/ECR"

#   image_name    = "${var.prefix}-${var.application_name}-${local.environment}" 
# }

module "VPC" {
  source = "../../Modules/VPC"

  env_name = local.environment
  vpc_name = local.vpc_name
  vpc_cdir_block = local.vpc_cdir_block
}