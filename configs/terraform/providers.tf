terraform {
  required_version = ">= 1.0"
  
  required_providers {
    yandex = {
      source  = "local/yandex-cloud/yandex"
      version = "0.130.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}
