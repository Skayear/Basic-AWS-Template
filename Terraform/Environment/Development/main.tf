locals {

  # count = var.create_environment ? 1 : 0
  
  application_name = var.application_name
  prefix           = var.prefix
  environment      = var.environment
  account_id       = var.account_id

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

  ####################
  ## Front config
  ####################
  front_task_definition_network_mode = "bridge" #"awsvpc"
  front_service_launch_type          = "EC2"
  front_load_balancer_container_port = 80
  #front_container_front_settings = jsondecode(file("${path.module}/variables/front_settings.json"))

  front_ecs_min_size         = 1
  front_ecs_desired_capacity = 1
  front_ecs_max_size         = 2

  front_container_list = [{
    container_name                 = "front"
    cpu                            = 512
    memory                         = 1700
    links                          = []
    container_port                 = 3000
    #container_env_parameters       = null
    #cloudwatch_log_group           = module.shared.log_group
    ecr_repository_url             = module.ecr.repository_url
    #load_balancer_target_group_arn = module.front.front_alb_target_group
    #container_env_parameters       = jsondecode(file("${path.module}/variables/front_settings.json"))
  }]

  front_load_balancer_certificate_arn     = ""
  front_health_check_path                 = "/"
  front_load_balancer_protcol             = "HTTP"
  front_target_group_registration_port    = 80
  front_target_group_registration_potocol = "HTTP"
  front_load_balancer_https               = true

  ############################
  ## SSH Bucket Config
  ############################
  ssh_bucket_acl        = "private"
  ssh_bucket_cors_rules = []

  ###########################
  ## Autoscaling Config
  ###########################
  ec2_min_size         = 2
  ec2_max_size         = 4
  ec2_desired_capacity = 2
  #aux_access_sg        = module.shared.rds_access_sg
  ec2_image_id         = "ami-06d19ceadc6ddf0d3" #"ami-014cdb1bfb3b2584f"
  ec2_instance_type    = "t3.medium"

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

module "RDS" {
  source = "../../Modules/RDS"

  identifier              = "${local.prefix}-${local.application_name}-db-${local.environment}"
  allocated_storage       = "20"
  engine                  = "postgres"
  engine_version          = "13.13"
  instance_class          = "db.t3.micro" #"db.t4g.micro"
  multi_az                = false
  database_name           = "wikijs"
  database_username       = "admin_wikijs" 
  subnet_ids              = module.public_subnets.subnet_ids
  subnet_group_id         = module.RDS_networking.subnet_group_id
  security_group_ids      = module.RDS_networking.security_group_ids
  deletion_protection     = false
  apply_immediately       = true
  storage_encrypted       = false
  monitoring_interval     = 0
  env_name                = var.environment
  publicly_accessible     = true
}

module "ecr" {
  source = "../../Modules/ECR"

  image_name    = "${var.prefix}-${var.application_name}-${local.environment}" 
}

module "VPC" {
  source = "../../Modules/VPC"

  env_name = local.environment
  vpc_name = local.vpc_name
  vpc_cdir_block = local.vpc_cdir_block
}

module "ecs_cluster" {
  source = "../../Modules/ECS"

  env_full_name = local.env_full_name

}

module "ecs_service_task" {
  source = "../../Modules/ECS_service_task_definitions"

  system_name = local.prefix
  env_name = var.environment
  service_full_name = local.prefix
  env_full_name = local.env_full_name
  region = var.region
  account_id = local.account_id
  
  cluster_id = module.ecs_cluster.cluster_id
  cluster_name = local.env_full_name
   
  task_definition_network_mode = "bridge" #"awsvpc"  
  service_launch_type = "EC2"
  load_balancer_container_port = 80
  load_balancer_target_group_arn = null #module.alb.load_balancer_target_group_arn
  security_group_ids = module.public_subnets.subnet_ids 
  subnet_ids = module.public_subnets.subnet_ids 
  ecs_min_size = 1
  ecs_desired_capacity = 1
  ecs_max_size = 2
  aux_access_sg = []
  
  /*
  container_name = var.container_name
  cpu = var.cpu
  memory = var.memory
  container_env_parameters = var.container_env_parameters
  container_port = var.container_port
  cloudwatch_log_group = var.cloudwatch_log_group
  ecr_repository_url = module.ecr.repository_url
  */

  container_list =  local.front_container_list

  vpc_id = module.VPC.vpc_id
}

# module "EC2_Autoscaling" {
#   source = "../../Modules/AutoScaling"

#   cluster_name = module.ecs_cluster.cluster_name
#   env_full_name = local.env_full_name
#   ssh_bucket = "${local.environment}-${local.application_name}-ssh-bucket"
#   subnet_ids = module.public_subnets.subnet_ids
#   ec2_min_size = local.ec2_min_size
#   ec2_max_size = local.ec2_max_size
#   ec2_desired_capacity = local.ec2_desired_capacity
#   aux_access_sg = module.RDS_networking.database_sg_id
#   ec2_image_id = local.ec2_image_id
#   ec2_instance_type = local.ec2_instance_type
#   vpc_id = module.VPC.vpc_id
#   #log_group = module.cloudwatch.log_group

#   # depends_on = [
#   #   module.ssh_s3
#   # ]
# }