# =============================================================================,
# outputs.tf - Valeurs exposees par le module,
# =============================================================================,
output "vm_name" {
  description = "Nom de la VM creee"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_id" {
  description = "ID Proxmox de la VM"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "ipv4_address" {
  description = "Adresse IPv4 de la VM (remontee par qemu-guest-agent)"
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
}
