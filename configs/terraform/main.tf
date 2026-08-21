# ============================================
# 1. VPC NETWORK
# ============================================

resource "yandex_vpc_network" "diploma" {
  name        = var.vpc_name
  description = "VPC network for diploma project"
}

# ============================================
# 2. PUBLIC SUBNETS
# ============================================

resource "yandex_vpc_subnet" "public" {
  for_each = var.public_subnet_cidrs
  
  name           = "public-${each.key}"
  description    = "Public subnet in ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.diploma.id
  v4_cidr_blocks = [each.value]
}

# ============================================
# 3. PRIVATE SUBNETS (with NAT)
# ============================================

resource "yandex_vpc_subnet" "private" {
  for_each = var.private_subnet_cidrs
  
  name           = "private-${each.key}"
  description    = "Private subnet in ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.diploma.id
  v4_cidr_blocks = [each.value]
  
  route_table_id = yandex_vpc_route_table.private_nat.id
}

# ============================================
# 4. NAT INSTANCE (для доступа в интернет из приватных подсетей)
# ============================================

resource "yandex_compute_disk" "nat_disk" {
  name  = "nat-disk"
  type  = "network-hdd"
  zone  = var.default_zone
  size  = var.vm_disk_size
  image_id = var.vm_image_id
}

resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  platform_id = var.vm_platform
  zone        = var.default_zone
  
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  boot_disk {
    disk_id = yandex_compute_disk.nat_disk.id
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.public[var.default_zone].id
    nat       = true
  }
  
  metadata = {
    user-data = "#cloud-config\nhostname: nat\nfqdn: nat.ru-central1.internal"
    ssh-keys  = "ubuntu:${file(var.ssh_public_key)}"
  }
  
  allow_stopping_for_update = true
}

# ============================================
# 5. ROUTE TABLE (для приватных подсетей)
# ============================================

resource "yandex_vpc_route_table" "private_nat" {
  name       = "private-nat-route"
  network_id = yandex_vpc_network.diploma.id
  
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat.network_interface.0.ip_address
  }
}

# ============================================
# 6. SECURITY GROUPS
# ============================================

# --- Bastion SG ---
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Web Servers SG ---
resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "HTTP from ALB"
    v4_cidr_blocks = ["10.0.0.0/16"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [yandex_vpc_subnet.public[var.default_zone].v4_cidr_blocks.0]
    port           = 22
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix Agent"
    v4_cidr_blocks = ["10.0.0.0/16"]
    port           = 10050
  }
  
  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Zabbix SG ---
resource "yandex_vpc_security_group" "zabbix" {
  name        = "zabbix-sg"
  description = "Security group for Zabbix server"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix web UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix web UI HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  
  ingress {
    protocol       = "TCP"
    description    = "Zabbix trapper from agents"
    v4_cidr_blocks = ["10.0.0.0/16"]
    port           = 10051
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [yandex_vpc_subnet.public[var.default_zone].v4_cidr_blocks.0]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Elasticsearch SG ---
resource "yandex_vpc_security_group" "elasticsearch" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch API"
    v4_cidr_blocks = ["10.0.0.0/16"]
    port           = 9200
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [yandex_vpc_subnet.public[var.default_zone].v4_cidr_blocks.0]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Kibana SG ---
resource "yandex_vpc_security_group" "kibana" {
  name        = "kibana-sg"
  description = "Security group for Kibana"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "Kibana web UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }
  
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    v4_cidr_blocks = [yandex_vpc_subnet.public[var.default_zone].v4_cidr_blocks.0]
    port           = 22
  }
  
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Application Load Balancer SG ---
resource "yandex_vpc_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  network_id  = yandex_vpc_network.diploma.id
  
  ingress {
    protocol       = "TCP"
    description    = "HTTP from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
  
  ingress {
    protocol       = "TCP"
    description    = "HTTPS from anywhere"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }
  
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================
# 7. BASTION HOST (Jump Host)
# ============================================

resource "yandex_compute_disk" "bastion_disk" {
  name  = "bastion-disk"
  type  = "network-hdd"
  zone  = var.default_zone
  size  = var.vm_disk_size
  image_id = var.vm_image_id
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  platform_id = var.vm_platform
  zone        = var.default_zone
  
  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory
    core_fraction = var.vm_core_fraction
  }
  
  boot_disk {
    disk_id = yandex_compute_disk.bastion_disk.id
  }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.public[var.default_zone].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }
  
  metadata = {
    user-data = "#cloud-config\nhostname: bastion\nfqdn: bastion.ru-central1.internal"
    ssh-keys  = "ubuntu:${file(var.ssh_public_key)}"
  }
  
  allow_stopping_for_update = true
}

# ============================================
# 8. OUTPUTS
# ============================================

output "bastion_public_ip" {
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
  description = "Public IP of bastion host (for SSH)"
}

output "bastion_private_ip" {
  value       = yandex_compute_instance.bastion.network_interface.0.ip_address
  description = "Private IP of bastion host"
}

output "nat_instance_ip" {
  value       = yandex_compute_instance.nat.network_interface.0.ip_address
  description = "Private IP of NAT instance"
}

output "vpc_id" {
  value       = yandex_vpc_network.diploma.id
  description = "VPC network ID"
