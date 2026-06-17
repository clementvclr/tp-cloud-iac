=============================================================================,
versions.tf — Déclaration du provider et de la version d'OpenTofu requise,
=============================================================================,
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}
