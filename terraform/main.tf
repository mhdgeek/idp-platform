terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-idp-platform"
}

module "dev" {
  source         = "./modules/namespace"
  name           = "dev"
  environment    = "dev"
  cpu_limit      = "2"
  memory_limit   = "2Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"
  max_pods       = 10
}

module "staging" {
  source         = "./modules/namespace"
  name           = "staging"
  environment    = "staging"
  cpu_limit      = "4"
  memory_limit   = "4Gi"
  cpu_request    = "1"
  memory_request = "1Gi"
  max_pods       = 20
}

module "prod" {
  source         = "./modules/namespace"
  name           = "prod"
  environment    = "prod"
  cpu_limit      = "8"
  memory_limit   = "8Gi"
  cpu_request    = "2"
  memory_request = "2Gi"
  max_pods       = 50
}

module "rbac_dev" {
  source      = "./modules/rbac"
  namespace   = "dev"
  environment = "dev"
  depends_on  = [module.dev]
}

module "rbac_staging" {
  source      = "./modules/rbac"
  namespace   = "staging"
  environment = "staging"
  depends_on  = [module.staging]
}

module "rbac_prod" {
  source      = "./modules/rbac"
  namespace   = "prod"
  environment = "prod"
  depends_on  = [module.prod]
}

module "netpol_dev" {
  source     = "./modules/network-policy"
  namespace  = "dev"
  depends_on = [module.dev]
}

module "netpol_staging" {
  source     = "./modules/network-policy"
  namespace  = "staging"
  depends_on = [module.staging]
}

module "netpol_prod" {
  source     = "./modules/network-policy"
  namespace  = "prod"
  depends_on = [module.prod]
}
