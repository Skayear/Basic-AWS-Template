variable "identifier" {
  description = "Identifier of database"
}
 
variable "env_name" {
  description = "The environment"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids"
}

variable "allocated_storage" {
  default     = "20"
  description = "The storage size in GB"
}

variable "instance_class" {
  description = "The instance type"
}

variable "multi_az" {
  default     = false
  description = "Muti-az allowed?"
}

variable "database_name" {
  description = "The database name"
}

variable "database_username" {
  description = "The username of the database"
}
 
variable "engine" {
  description = "The database engine"
}

variable "engine_version" {
  description = "The database engine version"
}

variable "publicly_accessible" {
  default = true
}

variable "deletion_protection" {
  default = false
}

variable "storage_encrypted" {
  default = false
}

variable "apply_immediately" {
  default = false
}

variable "monitoring_interval" {
  default = 0
}

variable "subnet_group_id" {
  description = "subnet group id"
}

variable "security_group_ids" {
  description = "security groups ids"
}