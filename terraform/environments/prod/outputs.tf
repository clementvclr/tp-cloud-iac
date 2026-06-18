# =============================================================================
# outputs.tf - Informations exposees apres deploiement
# =============================================================================

output "db_vm" {
  description = "Informations sur la VM base de donnees"
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
output "ansible_inventory" {
  description = "Structure d'inventaire Ansible (format JSON)"
  value = {
    database = {
      hosts = {
        "${module.vm_db.vm_name}" = {
          ansible_host = split("/", var.db_ip)[0]
        }
      }
    }
    app = {
      hosts = {
        "${module.vm_app.vm_name}" = {
          ansible_host = split("/", var.app_ip)[0]
        }
      }
    }
  }
}

