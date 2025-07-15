# DR Region Infrastructure (only when enable_dr is true)
module "dr_networking" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/networking"

  providers = {
    aws = aws.dr
  }

  project_name         = local.project_name
  availability_zones   = slice(data.aws_availability_zones.dr.names, 0, 2)
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
  tags                 = local.common_tags
}

module "dr_security" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.dr
  }

  project_name = local.project_name
  vpc_id       = module.dr_networking[0].vpc_id
  tags         = local.common_tags
}

module "dr_ecr" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/ecr"

  providers = {
    aws = aws.dr
  }

  tags = local.common_tags
}

# DR RDS Subnet Group (for read replica)
resource "aws_db_subnet_group" "dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name       = "${local.project_name}-dr-db-${random_id.suffix.hex}"
  subnet_ids = module.dr_networking[0].private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-dr-db-subnet-group"
  })
}

# DR ECS Infrastructure (scaled to 0 by default)
module "dr_ecs" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/ecs"

  providers = {
    aws = aws.dr
  }

  project_name          = local.project_name
  vpc_id                = module.dr_networking[0].vpc_id
  public_subnet_ids     = module.dr_networking[0].public_subnet_ids
  private_subnet_ids    = module.dr_networking[0].private_subnet_ids
  alb_security_group_id = module.dr_security[0].alb_security_group_id
  ecs_security_group_id = module.dr_security[0].ecs_security_group_id
  apache_repository_url = module.dr_ecr[0].apache_repository_url
  db_endpoint           = module.primary_rds.replica_endpoint != null ? module.primary_rds.replica_endpoint : module.primary_rds.db_endpoint
  db_name               = module.primary_rds.db_name
  db_password           = module.primary_secrets.db_password
  secret_arn            = var.enable_dr ? module.primary_secrets.dr_secret_arn : module.primary_secrets.secret_arn
  aws_region            = var.dr_region
  desired_count         = var.dr_killswitch ? 2 : 0 # Activate when killswitch enabled
  tags                  = local.common_tags
}