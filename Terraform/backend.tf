terraform {
  backend "s3" {
    bucket                  = "wikijs-terraform-state"
    key                     = "terraform.tfstate"
    region                  = "us-east-1"
    encrypt                 = true
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "dualboot-wiki"
  }
}