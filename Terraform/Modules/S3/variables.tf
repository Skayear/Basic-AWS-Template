variable "env_name" {
  description = "Name of the environment where the bucket is created."
}

variable "bucket_name" {
  description = "Name of the bucket."
}

variable "acl" {
  description = "ACL for the bucket"
}

variable "cors_rules_list" {
  description = "List of cors rules to attach to the bucket"
  
  type =  list(object({ 
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers = list(string)
    max_age_seconds = number 
  }))

}