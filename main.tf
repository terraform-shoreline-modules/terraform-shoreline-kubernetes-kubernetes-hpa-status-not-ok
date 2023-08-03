terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "kubernetes_hpa_status_incident" {
  source    = "./modules/kubernetes_hpa_status_incident"

  providers = {
    shoreline = shoreline
  }
}