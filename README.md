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
