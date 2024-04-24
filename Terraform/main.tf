locals {

  application_name = "wiki"
  prefix           = "wikijs"
  account_id       = "248817656838"
  region           = "us-east-1"
  
}

module "Development" {
  source = "./Environment/Development"

  #create_environment = true

  prefix = local.prefix
  environment         = "dev"
  application_name = local.application_name
  account_id = local.account_id
  region = local.region
  
}

# module "Production" {
#   source = "./Environment/Production"

#   #create_environment = false

#   prefix = local.prefix
#   environment         = "prod"
#   application_name = local.application_name
#   #account_id = local.account_id
#   region = local.region
  
# }