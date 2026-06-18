# TP Fil Rouge — Déploiement automatisé d'une infrastructure web

Déploiement reproductible d'une infrastructure **Wiki.js + PostgreSQL** sur Proxmox VE via cloud-init, OpenTofu et Ansible.

## Vue d'ensemble

Le projet déploie deux environnements identiques (`prod` et `dev`), chacun composé de 2 VMs :

- Une VM **base de données** (PostgreSQL 16)
- Une VM **applicative** (Wiki.js, qui se connecte à la base de l'autre VM)

L'environnement de production est exposé publiquement sur `http://82.64.141.52:3080` via un port forwarding NAT mis en place par le formateur sur le routeur en amont du Proxmox.

## Stack technique

| Outil | Rôle | Version |
|:------|:-----|:--------|
| cloud-init | Provisioning initial des VMs (utilisateur, clés SSH, paquets, durcissement) | natif Ubuntu cloud-image |
| OpenTofu | Description et création de l'infrastructure | >= 1.8 |
| Provider bpg/proxmox | Connecteur Proxmox pour OpenTofu | ~> 0.66 |
| Ansible | Configuration des middlewares (PostgreSQL, Wiki.js) | >= 2.15 |
| Proxmox VE | Hyperviseur cible | 9.2 |
| Ubuntu Server | OS des VMs | 24.04 LTS (Noble) |
| PostgreSQL | Base de données pour Wiki.js | 16 |
| Node.js | Runtime pour Wiki.js | 20 LTS |
| Wiki.js | Application wiki (latest release) | 2.x |

## Architecture

- Réseau interne Proxmox : 10.0.30.0/24, gateway 10.0.30.1, bridge vmbr0
- Prod : prod-wiki-db (VM 201, 10.0.30.201) + prod-wiki-app (VM 202, 10.0.30.202)
- Dev : dev-wiki-db (VM 211, 10.0.30.211) + dev-wiki-app (VM 212, 10.0.30.212)
- Template cloud-init : ubuntu-24-04-cloudinit (VM ID 9000)
- Accès externe au Proxmox : UI Proxmox sur 82.64.141.52:3006, SSH sur 82.64.141.52:3007
- Accès au service Wiki.js public : 82.64.141.52:3080 (NAT -> 10.0.30.202:3000)

## Structure du projet

- `cloud-init/user-data.yaml` : config cloud-init commune aux VMs
- `terraform/modules/vm/` : module réutilisable de création de VM Proxmox
- `terraform/environments/prod/` : environnement production (2 vCPU, 2 Go, 20 Go par VM)
- `terraform/environments/dev/` : environnement développement (1 vCPU, 1 Go, 10 Go par VM)
- `ansible/ansible.cfg` : configuration Ansible
- `ansible/inventory/prod.yml` et `dev.yml` : inventaires statiques
- `ansible/roles/common/` : paquets de base, hostname, UFW
- `ansible/roles/postgresql/` : PostgreSQL + base wikijs + règles pg_hba
- `ansible/roles/wikijs/` : Node.js + Wiki.js + service systemd
- `ansible/playbooks/site.yml` : playbook principal
- `scripts/generate-inventory.sh` : bonus — génère un inventaire Ansible depuis les outputs Terraform
- `docs/screenshots/` : captures d'écran de validation

## Prérequis (poste de travail)

Testé sur WSL2 Ubuntu 24.04. Installation :

    # OpenTofu
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method deb

    # Ansible et collections requises
    sudo apt install -y ansible
    ansible-galaxy collection install community.general community.postgresql

## Configuration SSH locale (bastion via ProxyJump)

Le Proxmox est exposé sur des ports non-standards (NAT du formateur). On utilise un bastion SSH pour atteindre les VMs internes. Créer `~/.ssh/config` :

    Host proxmox-tp
        HostName 82.64.141.52
        Port 3007
        User root
        IdentityFile ~/.ssh/tp_filrouge
        IdentitiesOnly yes

    Host wiki-db
        HostName 10.0.30.201
        User ansible
        IdentityFile ~/.ssh/tp_filrouge
        ProxyJump proxmox-tp

    Host wiki-app
        HostName 10.0.30.202
        User ansible
        IdentityFile ~/.ssh/tp_filrouge
        ProxyJump proxmox-tp

Pousser sa clé sur le Proxmox une seule fois :

    ssh-copy-id -i ~/.ssh/tp_filrouge.pub proxmox-tp

## Préparation Proxmox (one-shot)

Ces opérations sont à faire une seule fois sur le node Proxmox.

### 1. Activer le content-type snippets sur le datastore local

Nécessaire pour qu'OpenTofu puisse y uploader les fichiers cloud-init :

    ssh proxmox-tp "pvesm set local --content backup,iso,vztmpl,import,snippets"

### 2. Créer le template cloud-init Ubuntu 24.04 (VM ID 9000)

    ssh proxmox-tp
    cd /var/lib/vz/template/iso
    wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

    qm create 9000 --name ubuntu-24-04-cloudinit --memory 2048 --cores 2 \
        --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-single \
        --serial0 socket --vga serial0 --agent enabled=1

    qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
    qm set 9000 --scsi0 local-lvm:vm-9000-disk-0,discard=on,ssd=1
    qm set 9000 --ide2 local-lvm:cloudinit
    qm set 9000 --boot order=scsi0

    # Le Proxmox du formateur tourne en virtualisation imbriquée sans
    # extensions hardware exposées. On désactive l'accélération KVM et
    # on utilise un type CPU compatible émulation.
    qm set 9000 --kvm 0 --cpu qemu64

    qm template 9000
    exit

### 3. Créer un token API Proxmox

Dans l'UI Proxmox : Datacenter -> Permissions -> API Tokens -> Add

- User : root@pam
- Token ID : tp-filrouge
- Décocher Privilege Separation (sinon le token n'a aucune permission)
- Copier immédiatement le secret affiché (il n'est plus jamais montré)

Format final à utiliser : root@pam!tp-filrouge=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

## Déploiement

### Étape 1 — Infrastructure (OpenTofu)

Pour chaque environnement (prod ou dev) :

    cd terraform/environments/prod   # ou dev
    cp terraform.tfvars.example terraform.tfvars
    # Renseigner terraform.tfvars avec les vraies valeurs (token API, mot de passe SSH, etc.)
    tofu init
    tofu plan
    tofu apply

Résultat : 2 VMs sont créées sur Proxmox, démarrées, avec cloud-init exécuté (utilisateur ansible, clés SSH, qemu-guest-agent, durcissement SSH).

### Étape 2 — Configuration (Ansible)

Méthode 1 — inventaire statique :

    cd ansible
    ansible -i inventory/prod.yml all -m ping
    ansible-playbook -i inventory/prod.yml playbooks/site.yml

Méthode 2 (bonus) — inventaire généré dynamiquement depuis Terraform :

    ./scripts/generate-inventory.sh prod
    cd ansible
    ansible-playbook -i inventory/prod.generated.yml playbooks/site.yml

Le playbook exécute, dans l'ordre :

1. Rôle common sur les 2 VMs (paquets de base, hostname, UFW)
2. Rôle postgresql sur la VM database (PostgreSQL 16, base wikijs, pg_hba pour la VM app uniquement)
3. Rôle wikijs sur la VM app (Node.js 20, Wiki.js latest, service systemd, port 3000)

### Étape 3 — Accès

- Wiki.js prod : http://82.64.141.52:3080 (via NAT du formateur)
- Wiki.js dev : accessible en interne uniquement (10.0.30.212:3000), testable via un tunnel SSH :

      ssh -L 8081:10.0.30.212:3000 proxmox-tp
      # puis ouvrir http://localhost:8081 dans le navigateur

## Sécurité

- Aucun secret en clair dans le repo : *.tfvars, clés SSH privées et *.pem sont dans .gitignore
- Authentification SSH uniquement par clé sur les VMs (PasswordAuthentication no)
- PermitRootLogin no sur les VMs
- UFW activé sur toutes les VMs avec règles minimales (SSH + ports applicatifs)
- PostgreSQL n'accepte les connexions que depuis la VM applicative correspondante (pg_hba.conf restrictif)
- Token API Proxmox dédié, pas d'authentification par mot de passe pour OpenTofu (sauf SSH pour upload des snippets cloud-init, limite de l'API Proxmox)

## Portabilité multi-fournisseur

L'architecture est conçue pour faciliter un changement de fournisseur (par exemple Proxmox -> Azure) :

- La logique de création de VM est isolée dans un module unique (terraform/modules/vm/)
- Les environnements (prod, dev) appellent le module avec des paramètres : changer le module sous-jacent (par exemple modules/vm-azure/) suffirait à migrer
- Le code Ansible est totalement indépendant du fournisseur : il ne fait que du SSH vers des IPs

## Bonus implémentés

- Inventaire Ansible dynamique généré depuis les outputs Terraform via scripts/generate-inventory.sh
- Bastion SSH via ProxyJump (pas d'IP publique exposée par VM, surface d'attaque réduite)
- Idempotence : tous les rôles Ansible peuvent être rejoués sans casser l'existant

## Captures d'écran (docs/screenshots/)

## Captures d'écran de validation

Toutes les captures sont dans `docs/screenshots/` et prouvent le bon fonctionnement de chaque étape du déploiement.

### Infrastructure (OpenTofu)

- **`01-proxmox-vms-deployed-start.png`** : interface Proxmox au démarrage des VMs, prouvant que la création se fait bien via OpenTofu
- **`01-proxmox-vms-deployed.png`** : interface Proxmox après déploiement complet des 4 VMs (`prod-wiki-db` 201, `prod-wiki-app` 202, `dev-wiki-db` 211, `dev-wiki-app` 212) plus le template cloud-init `ubuntu-24-04-cloudinit` (VM 9000)
- **`07-tofu-plan-no-changes-prod.png`** : `tofu plan` sur l'environnement prod indiquant `No changes. Your infrastructure matches the configuration.`, ce qui prouve que le code Terraform correspond exactement à l'infrastructure réelle (pas de drift)
- **`07-tofu-plan-no-changes-dev.png`** : idem pour l'environnement dev, démontrant la reproductibilité dev/prod

### Cloud-init

- **`02-cloud-init-done.png`** : sortie SSH montrant `cloud-init status: done`, l'utilisateur `ansible` créé avec les bons groupes (`sudo`), et le log de fin d'exécution `cloud-init-done.log`. Preuve que cloud-init a bien préparé chaque VM dès le démarrage

### Ansible

- **`03-ansible-first-run.png`** : `PLAY RECAP` du premier passage du playbook, montrant les modifications appliquées (`changed=17` côté app, `changed=13` côté db, `failed=0` partout). Toutes les VMs ont été configurées avec succès
- **`04-ansible-idempotent.png`** : `PLAY RECAP` du second passage du playbook, montrant `changed=0` sur les deux VMs. Démonstration formelle de l'**idempotence** des rôles Ansible (critère explicite du TP)

### Service public accessible

- **`05-wikijs-public.png`** : Wiki.js en cours de setup, accessible depuis Internet sur `http://82.64.141.52:3080` (URL bien visible dans la barre d'adresse du navigateur). Le service est exposé publiquement via le port forwarding NAT (`82.64.141.52:3080` → `10.0.30.202:3000`) configuré par le formateur

### Bonus — Inventaire Ansible dynamique

- **`06-bonus-dynamic-inventory.png`** : exécution du script `scripts/generate-inventory.sh prod` montrant la génération automatique de l'inventaire Ansible à partir des outputs Terraform. Le fichier généré contient les bons hosts et IPs (`prod-wiki-db: 10.0.30.201`, `prod-wiki-app: 10.0.30.202`), récupérés directement depuis le state OpenTofu

## Auteurs

Groupe de 4 — VAUCLARE Clement, BARBESIER Axel, PINTO Axel, DURBEC Lucas

## Vérification de l'idempotence Ansible

Le critère d'évaluation Ansible mentionne explicitement l'idempotence. Pour la vérifier, il suffit de rejouer le playbook une seconde fois après un premier déploiement réussi :

    ansible-playbook -i inventory/prod.yml playbooks/site.yml

Lors du second passage, Ansible doit afficher `changed=0` pour la majorité des tâches (seules les tâches de redémarrage de service peuvent ressortir en changed selon l'état du système). C'est la preuve que les rôles convergent vers un état stable sans modifier inutilement le système.

## Procédure de destruction

Pour détruire complètement un environnement :

    cd terraform/environments/prod   # ou dev
    tofu destroy

Cela détruit les 2 VMs créées et supprime les snippets cloud-init associés sur Proxmox. Le template (VM 9000) n'est pas affecté.

## Migration vers un autre fournisseur de cloud

L'architecture isole le code spécifique à Proxmox dans le module `terraform/modules/vm/`. Pour migrer vers Azure :

1. Créer un module équivalent `terraform/modules/vm-azure/` avec les ressources Azure (`azurerm_linux_virtual_machine`, `azurerm_network_interface`, etc.)
2. Exposer la même interface (`var.vm_name`, `var.cpu_cores`, `var.memory_mb`, `var.ip_address`, `var.user_data_path`, etc.)
3. Modifier la ligne `source = "../../modules/vm"` dans `environments/prod/main.tf` et `environments/dev/main.tf` pour pointer vers le nouveau module
4. Adapter `terraform.tfvars` aux variables propres à Azure

Le code Ansible n'a pas besoin d'être modifié : il s'appuie uniquement sur SSH vers des IPs, indépendamment du fournisseur sous-jacent.

## Historique Git

Le projet suit la convention de commits atomiques avec préfixes sémantiques :

- `chore:` configuration projet (gitignore, structure)
- `feat:` ajout de fonctionnalité (rôle Ansible, module Terraform)
- `fix:` correction de bug
- `docs:` mise à jour documentation
=======
Groupe de 4 — VAUCLARE Clement, DURBEC Lucas, BARBESIER Axel, PINTO Axel
