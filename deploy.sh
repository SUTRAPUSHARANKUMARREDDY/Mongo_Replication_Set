#!/bin/bash

# Variable to determine if it's the first run
FIRST_RUN=true	

# Install jq only on first run
if $FIRST_RUN; then
  sudo apt-get update && sudo apt-get install -y jq
fi

# Run Terraform init, plan, and apply
terraform init
terraform plan
terraform apply -auto-approve

# Create an inventory file for Ansible
vm_group="vm_group"
vm_admin_user="adminuser"
vm_ssh_password="P@ssw0rd1234!"

# Create an inventory file only if it does not exist or it's the first run
if $FIRST_RUN || [ ! -f inventory.ini ]; then
  echo "[$vm_group]" > inventory.ini
fi

# Create a temporary inventory file for new instances only if not first run
if ! $FIRST_RUN; then
  echo "[$vm_group]" > new_instances_inventory.ini
fi

# Get the private IPs of the virtual machines
vm_ips_json=$(terraform output -json vm_private_ips)

# Create inventory entries for each instance
for ip in $(echo "$vm_ips_json" | jq -r '.[]'); do
  if ! grep -q "$ip" inventory.ini; then
    echo "$ip" >> inventory.ini
    if ! $FIRST_RUN; then
      echo "$ip" >> new_instances_inventory.ini
    fi
  fi
done

# Print inventory files
cat inventory.ini
if ! $FIRST_RUN; then
  cat new_instances_inventory.ini
fi

# Run Ansible playbook
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no"
vm_private_ips_array=($(echo $vm_ips_json | jq -r '.[]'))
for ip in "${vm_private_ips_array[@]}"; do
  echo "Copying SSH key to $ip"
  ./ssh_copy_id_expect.sh "$ip" "$vm_ssh_password"
done

# Sleep for a while before running Ansible playbook
echo "Sleeping for a while before running Ansible playbook"
sleep $(if $FIRST_RUN; then echo 120; else echo 120; fi)

# Run appropriate Ansible playbook based on FIRST_RUN
ansible-playbook -i $(if $FIRST_RUN; then echo inventory.ini; else echo new_instances_inventory.ini; fi) --private-key=./id_rsa -u $vm_admin_user $(if $FIRST_RUN; then echo playbook.yml; else echo playbook_NFT.yml; fi)

# Run Ansible playbook to add new instances to the replica set only if not first run
if ! $FIRST_RUN; then
  ansible-playbook -i inventory.ini --private-key=./id_rsa -u $vm_admin_user add_instances_to_replica_set.yml
fi

# Clean up the temporary inventory file only if not first run
if ! $FIRST_RUN; then
  rm new_instances_inventory.ini
fi