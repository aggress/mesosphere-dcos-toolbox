#!/bin/sh

cd ~/code/terraform-ansible-dcos
terraform init
terraform get
terraform apply -auto-approve
sleep 30
sh ansibilize.sh
cd ~/code/dcos-ansible
ansible-playbook -i hosts -u centos -b main.yaml
