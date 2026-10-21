#!/usr/bin/env bash

# stop on any error, undefined variable or failed pipe
set -euo pipefail

# go to the repo root (where this script is), so it works from any folder
cd "$(dirname "$0")"

echo "Starting deployment..."

echo "1- apply tf to setup infra"
cd Terraform
terraform init
terraform apply -auto-approve

echo "2- generate ansible inventory from tf outputs"
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini

echo "3- setting up ansible"
cd ../ansible

# .vault_pass is gitignored, so it has to be created locally before deploying
if [ ! -f .vault_pass ]; then
  echo "ansible/.vault_pass not found, you don't have the vault password"
  exit 1
fi
ansible-galaxy collection install -r requirements.yml

echo "4- waiting for servers to accept ssh"
ansible all -m ansible.builtin.wait_for_connection -a "timeout=300"

echo "5- running playbook"
ansible-playbook playbook.yml

echo "Done, app is up at http://$(terraform -chdir=../Terraform output -raw app_public_ip)"
