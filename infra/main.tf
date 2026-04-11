module "networking" {
  source = "./modules/networking"

  environment = var.environment
  project     = var.project
  vpc_cidr    = var.vpc_cidr
  app_port    = var.app_port
}

module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
  project     = var.project
}

module "rds" {
  source = "./modules/rds"

  environment       = var.environment
  project           = var.project
  subnet_ids        = module.networking.public_subnet_ids
  security_group_id = module.networking.rds_security_group_id
}

module "identity" {
  source = "./modules/identity"

  environment        = var.environment
  project            = var.project
  github_repo        = "liatrio-forge/emerald-grove-pet-clinic-matt-rucker"
  ecr_repository_arn = module.ecr.repository_arn
}

module "ecs" {
  source = "./modules/ecs"

  environment                 = var.environment
  project                     = var.project
  container_image             = "${module.ecr.repository_url}:latest"
  subnet_ids                  = module.networking.public_subnet_ids
  security_group_id           = module.networking.ecs_security_group_id
  target_group_arn            = module.networking.alb_target_group_arn
  db_endpoint                 = module.rds.db_endpoint
  db_name                     = module.rds.db_name
  db_username                 = module.rds.db_username
  db_password_secret_arn      = module.rds.db_password_secret_arn
  anthropic_api_key_secret_arn = module.rds.anthropic_api_key_secret_arn
}
