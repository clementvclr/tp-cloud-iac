# =============================================================================
# variables.tf — Paramètres d'entrée du module de création de VM
# =============================================================================

variable "vm_name" {
  description = "Nom de la VM (sera aussi le hostname)"
  type        = string
}

variable "vm_id" {
  description = "ID numérique unique de la VM dans Proxmox (ex: 200, 201...)"
  type        = number
}

variable "target_node" {
  description = "Nom du node Proxmox sur lequel créer la VM"
  type        = string
}

variable "template_id" {
  description = "ID du template cloud-init Proxmox à cloner"
  type        = number
}

variable "cpu_cores" {
  description = "Nombre de cœurs CPU"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "RAM en mégaoctets"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Taille du disque principal en gigaoctets"
  type        = number
  default     = 20
}

variable "storage_pool" {
  description = "Nom du datastore Proxmox pour le disque de la VM (ex: local-lvm)"
  type        = string
}

variable "snippet_storage" {
  description = "Nom du datastore Proxmox pour les snippets cloud-init (ex: local)"
  type        = string
}

variable "network_bridge" {
  description = "Bridge réseau Proxmox (ex: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Adresse IP statique en notation CIDR (ex: 192.168.1.50/24), ou 'dhcp'"
  type        = string
}

variable "gateway" {
  description = "Passerelle réseau (ignoré si ip_address = dhcp)"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Liste des serveurs DNS"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "user_data_path" {
  description = "Chemin vers le fichier user-data cloud-init"
  type        = string
}

variable "tags" {
  description = "Liste de tags Proxmox pour identifier la VM (ex: [\"prod\", \"web\"])"
  type        = list(string)
  default     = []
}
