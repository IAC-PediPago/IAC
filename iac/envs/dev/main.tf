module "frontend_hosting" {
  source      = "../../modules/frontend_hosting"
  name_prefix = local.name_prefix
  account_id  = local.account_id
  tags        = var.tags
}

module "api_auth" {
  source      = "../../modules/api_auth"
  name_prefix = local.name_prefix
  aws_region  = var.aws_region
  tags        = var.tags
}

module "edge" {
  source = "../../modules/edge"

  name_prefix = local.name_prefix
  tags        = var.tags

  frontend_bucket_name                 = module.frontend_hosting.bucket_name
  frontend_bucket_arn                  = module.frontend_hosting.bucket_arn
  frontend_bucket_regional_domain_name = module.frontend_hosting.bucket_regional_domain_name

  api_origin_domain = module.api_auth.api_origin_domain

  # placeholder (sin dominio real)
  enable_route53      = false
  route53_zone_id     = ""
  route53_record_name = ""
  acm_certificate_arn = ""
}

