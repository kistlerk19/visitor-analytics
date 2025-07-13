# Data sources for availability zones
data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "dr" {
  provider = aws.dr
  state    = "available"
}

# Primary Region Infrastructure
module "primary_networking" {
  source = "./modules/networking"

  providers = {
    aws = aws.primary
  }

  project_name         = local.project_name
  availability_zones   = slice(data.aws_availability_zones.primary.names, 0, 2)
  vpc_cidr             = "11.0.0.0/16"
  public_subnet_cidrs  = ["11.0.1.0/24", "11.0.2.0/24"]
  private_subnet_cidrs = ["11.0.3.0/24", "11.0.4.0/24"]
  tags                 = local.common_tags
}

module "primary_security" {
  source = "./modules/security"

  providers = {
    aws = aws.primary
  }

  project_name = local.project_name
  vpc_id       = module.primary_networking.vpc_id
  tags         = local.common_tags
}

module "primary_ecr" {
  source = "./modules/ecr"

  providers = {
    aws = aws.primary
  }

  tags = local.common_tags
}

module "primary_secrets" {
  source = "./modules/secrets"

  providers = {
    aws    = aws.primary
    aws.dr = aws.dr
  }

  project_name = local.project_name
  enable_dr    = var.enable_dr
  tags         = local.common_tags
}

module "primary_rds" {
  source = "./modules/rds"

  providers = {
    aws    = aws.primary
    aws.dr = aws.dr
  }

  project_name             = local.project_name
  private_subnet_ids       = module.primary_networking.private_subnet_ids
  rds_security_group_id    = module.primary_security.rds_security_group_id
  db_password              = module.primary_secrets.db_password
  enable_dr                = var.enable_dr
  dr_subnet_group_name     = var.enable_dr ? aws_db_subnet_group.dr[0].name : ""
  dr_rds_security_group_id = var.enable_dr ? module.dr_security[0].rds_security_group_id : ""
  tags                     = local.common_tags
}

module "primary_ecs" {
  source = "./modules/ecs"

  providers = {
    aws = aws.primary
  }

  project_name          = local.project_name
  vpc_id                = module.primary_networking.vpc_id
  public_subnet_ids     = module.primary_networking.public_subnet_ids
  private_subnet_ids    = module.primary_networking.private_subnet_ids
  alb_security_group_id = module.primary_security.alb_security_group_id
  ecs_security_group_id = module.primary_security.ecs_security_group_id
  apache_repository_url = module.primary_ecr.apache_repository_url
  db_endpoint           = module.primary_rds.db_endpoint
  db_name               = module.primary_rds.db_name
  db_password           = module.primary_secrets.db_password
  secret_arn            = module.primary_secrets.secret_arn
  aws_region            = var.primary_region
  desired_count         = 2
  image_tag             = var.image_tag
  tags                  = local.common_tags
}