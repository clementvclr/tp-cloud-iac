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
