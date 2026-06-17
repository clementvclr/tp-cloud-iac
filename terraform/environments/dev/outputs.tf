# =============================================================================,
# outputs.tf — Informations exposées après déploiement,
# =============================================================================,
output "db_vm" {
  description = "Informations sur la VM base de données"
  value = {
    name = module.vm_db.vm_name
    id   = module.vm_db.vm_id
    ipv4 = module.vm_db.ipv4_address
  }
}

output "app_vm" {
  description = "Informations sur la VM applicative"
  value = {
    name = module.vm_app.vm_name
    id   = module.vm_app.vm_id
    ipv4 = module.vm_app.ipv4_address
  }
}
