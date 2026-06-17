=============================================================================,
main.tf — Environnement PROD : 1 VM PostgreSQL + 1 VM Wiki.js,
=============================================================================,
locals {
  user_data_path = "${path.module}/../../../cloud-init/user-data.yaml"
}

VM 1 — Base de données PostgreSQL,
module "vm_db" {
  source = "../../modules/vm"

  vm_name         = "prod-wiki-db"
  vm_id           = 201
  target_node     = var.target_node
  template_id     = var.template_id
  cpu_cores       = 2
  memory_mb       = 2048
  disk_size_gb    = 20
  storage_pool    = var.storage_pool
  snippet_storage = var.snippet_storage
  network_bridge  = var.network_bridge
  ip_address      = var.db_ip
  gateway         = var.gateway
  user_data_path  = local.user_data_path
  tags            = ["prod", "database", "postgresql"]
}

VM 2 — Application Wiki.js,
module "vm_app" {
  source = "../../modules/vm"

  vm_name         = "prod-wiki-app"
  vm_id           = 202
  target_node     = var.target_node
  template_id     = var.template_id
  cpu_cores       = 2
  memory_mb       = 2048
  disk_size_gb    = 20
  storage_pool    = var.storage_pool
  snippet_storage = var.snippet_storage
  network_bridge  = var.network_bridge
  ip_address      = var.app_ip
  gateway         = var.gateway
  user_data_path  = local.user_data_path
  tags            = ["prod", "app", "wikijs"]
}
