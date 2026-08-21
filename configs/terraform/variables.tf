variable "yc_token" {
  description = "IAM token for Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "zones" {
  description = "Availability zones for VMs"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "diploma-vpc"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.1.0/24"
    "ru-central1-b" = "10.0.2.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.0.11.0/24"
    "ru-central1-b" = "10.0.12.0/24"
  }
}

variable "ssh_public_key" {
  description = "Path to public SSH key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_platform" {
  description = "Platform type for VMs (Intel Ice Lake)"
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_core_fraction" {
  description = "CPU core fraction (20% for preemptible)"
  type        = number
  default     = 20
}

variable "vm_memory" {
  description = "Memory in GB"
  type        = number
  default     = 4
}

variable "vm_disk_size" {
  description = "Disk size in GB (HDD)"
  type        = number
  default     = 10
}

variable "vm_image_id" {
  description = "Ubuntu 22.04 LTS image ID in Yandex Cloud"
  type        = string
  default     = "f8d806c8slu9j1pa87msc"
}

variable "vm_preemptible" {
  description = "Use preemptible instances (cheaper, max 24h)"
  type        = bool
  default     = true
}
