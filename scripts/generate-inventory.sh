#!/bin/bash
# =============================================================================
# generate-inventory.sh - Genere un inventaire Ansible YAML depuis Terraform
# Usage: ./scripts/generate-inventory.sh <env>
#   Exemple: ./scripts/generate-inventory.sh prod
# =============================================================================

set -e

ENV="${1:-prod}"
TF_DIR="$(dirname "$0")/../terraform/environments/${ENV}"
OUT_FILE="$(dirname "$0")/../ansible/inventory/${ENV}.generated.yml"

if [ ! -d "$TF_DIR" ]; then
  echo "Erreur: dossier terraform $TF_DIR introuvable"
  exit 1
fi

echo "[*] Recuperation de l'inventaire depuis Terraform (env: $ENV)..."

cd "$TF_DIR"
INVENTORY_JSON=$(tofu output -json ansible_inventory)

cd - > /dev/null

echo "[*] Generation de $OUT_FILE..."

cat > "$OUT_FILE" << EOF
---
# =============================================================================
# Inventaire genere automatiquement depuis Terraform - NE PAS EDITER A LA MAIN
# Genere par: scripts/generate-inventory.sh ${ENV}
# Environnement: ${ENV}
# =============================================================================

all:
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/tp_filrouge
    ansible_ssh_common_args: '-o ProxyJump=proxmox-tp -o StrictHostKeyChecking=no'
    ansible_python_interpreter: /usr/bin/python3

  children:
EOF

# Conversion JSON -> YAML via Python
python3 << PYEOF >> "$OUT_FILE"
import json
import sys

data = json.loads('''$INVENTORY_JSON''')

for group, group_data in data.items():
    print(f"    {group}:")
    print(f"      hosts:")
    for host, host_vars in group_data.get("hosts", {}).items():
        print(f"        {host}:")
        for key, value in host_vars.items():
            print(f"          {key}: {value}")
PYEOF

echo "[OK] Inventaire genere: $OUT_FILE"
echo ""
echo "Pour l'utiliser:"
echo "  cd ansible"
echo "  ansible-playbook -i inventory/${ENV}.generated.yml playbooks/site.yml"

