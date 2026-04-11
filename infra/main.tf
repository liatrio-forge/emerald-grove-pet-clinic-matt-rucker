module "networking" {
  source = "./modules/networking"

  environment = var.environment
  project     = var.project
  vpc_cidr    = var.vpc_cidr
  app_port    = var.app_port
}
