# =============================================================================,
# main.tf — Environnement DEV : copie iso-fonctionnelle de prod, specs réduites,
# =============================================================================,
locals {
  user_data_path = "${path.module}/../../../cloud-init/user-data.yaml"
}

VM 1 — Base de données PostgreSQL (dev),
module "vm_db" {
  source = "../../modules/vm"

  vm_name         = "dev-wiki-db"
  vm_id           = 211
  target_node     = var.target_node
  template_id     = var.template_id
  cpu_cores       = 1
  memory_mb       = 1024
  disk_size_gb    = 10
  storage_pool    = var.storage_pool
  snippet_storage = var.snippet_storage
  network_bridge  = var.network_bridge
  ip_address      = var.db_ip
  gateway         = var.gateway
  user_data_path  = local.user_data_path
  tags            = ["dev", "database", "postgresql"]
}

VM 2 — Application Wiki.js (dev),
module "vm_app" {
  source = "../../modules/vm"

  vm_name         = "dev-wiki-app"
  vm_id           = 212
  target_node     = var.target_node
  template_id     = var.template_id
  cpu_cores       = 1
  memory_mb       = 1024
  disk_size_gb    = 10
  storage_pool    = var.storage_pool
  snippet_storage = var.snippet_storage
  network_bridge  = var.network_bridge
  ip_address      = var.app_ip
  gateway         = var.gateway
  user_data_path  = local.user_data_path
  tags            = ["dev", "app", "wikijs"]
}
