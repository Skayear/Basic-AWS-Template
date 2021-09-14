
terraform {
  required_version = ">= 1.0.1"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}
