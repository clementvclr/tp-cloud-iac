TP Fil Rouge — Déploiement automatisé d'une infrastructure web,
Déploiement reproductible d'une infrastructure Wiki.js (app + base PostgreSQL) sur Proxmox via cloud-init, OpenTofu et Ansible.

Stack technique,
cloud-init : provisioning initial des VMs,
OpenTofu : description de l'infrastructure (Infrastructure as Code),
Ansible : configuration des middlewares (PostgreSQL, Wiki.js),
Proxmox VE : hyperviseur cible (architecture conçue pour être portable Azure),

Structure du projet,
cloud-init/ : fichiers user-data pour cloud-init,
terraform/ : code OpenTofu
modules/vm/ : module réutilisable de création de VM,
environments/ : environnements (dev, prod),
,
ansible/ : playbooks et rôles Ansible
inventory/,
roles/,
playbooks/,
,

Prérequis,
OpenTofu >= 1.8,
Ansible >= 2.15,
Accès à un node Proxmox VE avec un token API,

Déploiement,
À compléter au fur et à mesure du projet.

Auteurs,
Groupe de 4 — Axel BARBESIER, Axel PINTO, Luca DURBEC, Clément VAUCLARE

Étape 1 — Cloud-init,
Le fichier cloud-init/user-data.yaml est exécuté au premier démarrage de chaque VM créée par OpenTofu. Il :

Met à jour le système (apt update && apt upgrade),
Installe qemu-guest-agent (pour la visibilité Proxmox) et python3 (pour Ansible),
Crée l'utilisateur ansible avec sudo sans mot de passe,
Dépose les clés SSH publiques des membres du groupe,
Durcit la configuration SSH (pas de root login, pas d'auth par mot de passe),

Les clés SSH publiques sont commitées en clair dans ce fichier — c'est OK car les clés publiques sont prévues pour être partagées. Les clés privées correspondantes sont gérées par chaque membre individuellement et ne sont JAMAIS commitées (cf. .gitignore).

## Étape 1 — Cloud-init

Le fichier `cloud-init/user-data.yaml` est exécuté au premier démarrage de chaque VM créée par OpenTofu. Il :

- Met à jour le système (`apt update && apt upgrade`)
- Installe `qemu-guest-agent` (pour la visibilité Proxmox) et `python3` (pour Ansible)
- Crée l'utilisateur `ansible` avec sudo sans mot de passe
- Dépose les clés SSH publiques des membres du groupe
- Durcit la configuration SSH (pas de root login, pas d'auth par mot de passe)

Les clés SSH publiques sont commitées en clair dans ce fichier — c'est OK car les clés **publiques** sont prévues pour être partagées. Les clés **privées** correspondantes sont gérées par chaque membre individuellement et ne sont JAMAIS commitées (cf. `.gitignore`).

## Étape 2 — OpenTofu

### Architecture du code

Le code OpenTofu suit un modèle module + environnements :

- `terraform/modules/vm/` : module réutilisable de création de VM Proxmox avec cloud-init
- `terraform/environments/prod/` : environnement de production (2 vCPU, 2 Go RAM, 20 Go)
- `terraform/environments/dev/` : environnement de développement (1 vCPU, 1 Go RAM, 10 Go)

Cette structure permet de redéployer un environnement strictement identique en changeant uniquement les valeurs du fichier `terraform.tfvars`.

### Déploiement

bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec les vraies valeurs Proxmox
tofu init
tofu plan
tofu apply


Le déploiement crée 2 VMs :

- `prod-wiki-db` (VM ID 201) : future base PostgreSQL
- `prod-wiki-app` (VM ID 202) : future application Wiki.js


### Procédure de déploiement vérifiée

1. Créer le template cloud-init sur Proxmox (une seule fois) :

bash
   ssh -p 3007 root@<proxmox-host>
   cd /var/lib/vz/template/iso
   wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
   qm create 9000 --name ubuntu-24-04-cloudinit --memory 2048 --cores 2 \
     --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-single \
     --serial0 socket --vga serial0 --agent enabled=1
   qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
   qm set 9000 --scsi0 local-lvm:vm-9000-disk-0,discard=on,ssd=1
   qm set 9000 --ide2 local-lvm:cloudinit
   qm set 9000 --boot order=scsi0
   qm set 9000 --kvm 0 --cpu qemu64    # nécessaire pour virtualisation imbriquée
   qm template 9000


2. Activer le content type `snippets` sur le datastore `local` (une seule fois) :
bash
   pvesm set local --content backup,iso,vztmpl,import,snippets


3. Déployer l'infrastructure :
bash
   cd terraform/environments/prod
   cp terraform.tfvars.example terraform.tfvars
   # éditer terraform.tfvars avec les vraies valeurs
   tofu init
   tofu plan
   tofu apply
