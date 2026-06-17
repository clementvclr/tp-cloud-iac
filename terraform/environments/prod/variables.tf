=============================================================================,
variables.tf — Variables d'environnement (prod),
=============================================================================,
---- Connexion Proxmox ----,
variable "proxmox_endpoint" {
  description = "URL complète de l'API Proxmox (ex: https://1.2.3.4:8006/)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token API Proxmox au format USER@REALM!TOKENID=UUID"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Désactive la vérification TLS (utile pour les certifs auto-signés)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "Utilisateur SSH sur le node Proxmox (pour upload snippets)"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "Mot de passe SSH sur le node Proxmox"
  type        = string
  sensitive   = true
}

---- Infra ----,
variable "target_node" {
  description = "Nom du node Proxmox cible"
  type        = string
}

variable "template_id" {
  description = "ID du template cloud-init à cloner"
  type        = number
}

variable "storage_pool" {
  description = "Datastore pour les disques VM"
  type        = string
}

variable "snippet_storage" {
  description = "Datastore pour les snippets cloud-init"
  type        = string
  default     = "local"
}

variable "network_bridge" {
  description = "Bridge réseau"
  type        = string
  default     = "vmbr0"
}

variable "gateway" {
  description = "Passerelle réseau"
  type        = string
}

variable "db_ip" {
  description = "IP de la VM base de données (CIDR)"
  type        = string
}

variable "app_ip" {
  description = "IP de la VM applicative (CIDR)"
  type        = string
}
