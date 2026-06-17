# =============================================================================
# main.tf — Création d'une VM Proxmox avec cloud-init attaché
# =============================================================================

# Upload du fichier user-data cloud-init comme "snippet" sur Proxmox.
# Proxmox utilisera ce snippet comme source de configuration cloud-init.
resource "proxmox_virtual_environment_file" "user_data" {
  content_type = "snippets"
  datastore_id = var.snippet_storage
  node_name    = var.target_node

  source_file {
    path      = var.user_data_path
    file_name = "${var.vm_name}-user-data.yaml"
  }
}

# Création effective de la VM par clonage du template cloud-init.
resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.target_node
  tags        = var.tags
  description = "VM gérée par OpenTofu — TP Fil Rouge"

  # Clonage du template (full clone = indépendant du template d'origine)
  clone {
    vm_id = var.template_id
    full  = true
  }

  # Activation de l'agent QEMU (installé via cloud-init) pour que Proxmox
  # remonte l'IP et l'état réel de la VM
  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = var.disk_size_gb
    file_format  = "raw"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # Configuration cloud-init injectée dans la VM
  initialization {
    datastore_id = var.storage_pool

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.ip_address == "dhcp" ? null : var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    # Référence au snippet user-data uploadé plus haut
    user_data_file_id = proxmox_virtual_environment_file.user_data.id
  }

  # Empêche Terraform de recréer la VM si le template change après coup
  lifecycle {
    ignore_changes = [
      clone,
    ]
  }
}
