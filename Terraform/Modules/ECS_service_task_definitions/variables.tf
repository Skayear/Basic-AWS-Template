########################
## Global Vars 
######################## 
variable "system_name" {
  description = "Name of the system where the task is created."
}

variable "env_name" {
  description = "Name of the environment where the task is created."
}

variable "service_full_name" {
  description = "Name of the environment and system where the task is created."
}

variable "env_full_name" {
  description = "Name of the environment with the prfix"
}

variable "region" {
  description = "Region where all the resources will be created"
}

variable "account_id" {
  description = "Id of the account where all  the resources will be created"
}

########################
## ECS Cluster data
########################
variable "cluster_id" {
  description = "Id of the cluster where the service is created."
}

variable "cluster_name" {
  description = "Name of the cluster where the service is created."
}

##########################
## Task definition vars
##########################  
variable "task_definition_network_mode" {
  description = "Network mode for the task definition."
}
  
variable "service_launch_type" {
  description = "Service lauch type."
}

variable "load_balancer_container_port" {
  description = "Port of the container fowarded by the load balancer."
}

variable "load_balancer_target_group_arn" {
  description = "ARN of the service load balancer."
} 
 
variable "security_group_ids" {
  type        = list(string)
  description = "The SGs to use"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The private subnets to use"
} 

variable "ecs_min_size" {
  description = "Minimum capacity of ECS tasks" 
}

variable "ecs_desired_capacity" {
  description = "Desired capacity of ECS tasks" 
}

variable "ecs_max_size" {
  description = "Maximum capacity of ECS tasks" 
}
 
variable "vpc_id" {
  description = "VPC where the resource is going to be created." 
}

variable "aux_access_sg" {
  description = "Security group to access different resources"
  type = list(string)
}

####################
## Container Vars 
####################
variable "container_list" {
  description = "List of containers to create in the task"
  type = list(object({
    container_name = string
    cpu = number 
    memory = number
    links  = list(string)
    container_port = number
    ecr_repository_url = string
    #load_balancer_target_group_arn = string
  }))
}
