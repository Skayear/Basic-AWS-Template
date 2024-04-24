variable "env_name" {
  description = "Name of the environment. "
}

variable "vpc_id" {
  description = "Id of the VPC where the SubNets will be created"
}

variable "igw_id" {
  description = "Id of the Internet Gateway used with the SubNets"
}

variable "subnet_name" {
  description = "Name of the subnets that are going to be created. It will concat the AZ where is created"
}
  
variable "region" {
  description = "AWS region where the subnets are going to be created"
}

variable "subnet_list" {
  description = "List of letters that corresponds to the Availability Zone (AZ) where the subnets are going to be created. It will create 1 subnet for each AZ"
  type = list(object({
        az = string
        cidr_block= string
    }))
}

variable "privacy" {
  description = "Specifies the privacy of the subnets to be created, the options are: public, private, isolated"
  type = string
}