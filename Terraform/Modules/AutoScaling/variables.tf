variable "cluster_name" {
  description = "Name of the ECS cluster"
}
 
variable "env_full_name" {
  description = "Env full name"
}
  
variable "ssh_bucket" { 
} 


variable "subnet_ids" {
  
}

variable "ec2_min_size" {
  
}

variable "ec2_max_size" {
  
}

variable "ec2_desired_capacity" {
  
}

variable "aux_access_sg" {
  
}

variable "ec2_image_id" {
  
}

variable "ec2_instance_type" {
  
}

variable "vpc_id" {
  
}

variable "autoscaling_count_variation_up"{
  default = 1
}

variable "autoscaling_count_variation_down"{
  default = -1
}

# variable "log_group" {
  
# }
