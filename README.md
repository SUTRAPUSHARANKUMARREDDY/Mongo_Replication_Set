# Mongo_Replication_Set

Steps to run the script: <br />
Clone the repository in the jump host<br />

 Create a ssh key using “ ssh-keygen -t rsa -b 4096 -f ./id_rsa -N ' ' “<br />

- vim main.tf <br />
- Edit the variables create_new_resources, instance_count, existing_vnet_name, new_vnet_name, existing_resource_group_name, new_resource_group_name, existing_subnet_name, new_subnet_name any other required details.<br />
- Save the file and exit <br />

- vim deploy.sh<br />
- Edit the variable FIRST_RUN<br />
-Save the file and exit <br />

bash deploy.sh<br />

 

Steps to Lock the primary MongoDB to not terminate<br />
login to Azure console <br />

List the primary MongoDB instance and related resources<br />

Go to each resource and lock the resource<br />


 

The main.tf file is the primary Terraform script to deploy a set of Linux virtual machines on Azure with MongoDB installed. The script includes resource definitions for Azure services such as resource group, virtual network, subnet, network interface, and Linux virtual machines. A peering is also established between new and existing networks if new resources are created.<br />

deploy.sh is a bash script that handles the orchestration of this deployment. It first runs Terraform commands to create the infrastructure, then generates Ansible inventory files based on the Terraform output. The script then copies SSH keys to the newly created instances and finally runs the appropriate Ansible playbook depending on whether it's the first run or not.<br />

The playbook.yml and playbook_NFT.yml files are Ansible playbooks to configure MongoDB and the replica set on the newly created instances. They handle tasks such as package updates, MongoDB installation and configuration, and replica set initiation.<br />

The add_instances_to_replica_set.yml playbook is used to add new instances to the MongoDB replica set. It first identifies the primary MongoDB instance and then adds the new instances to the replica set.<br />

ssh_copy_id_expect.sh is an Expect script that automates the process of copying SSH keys to the new instances. Expect is a tool for automating interactive applications such as ssh, ftp, passwd, etc.<br />

 

 

Environment setup:<br />

You must have a Linux-based system or a system that can run bash and expect scripts.<br />

Ansible, Terraform, and Expect should be installed on the system.<br />

You should have an SSH key pair available on the system where the scripts are running. If not, you can generate one using ssh-keygen.<br />

The system should have internet access to download and install required packages.<br />

Software requirements:<br />

Ansible (Version 2.8 or later recommended)<br />

Terraform (Version 0.12 or later recommended)<br />

Expect scripting language<br />

MongoDB<br />

jq (Command-line JSON processor)<br />

GNU Privacy Guard (gnupg)<br />

Azure Cloud Provider:<br />

You need an active Azure subscription.<br />

The Azure CLI should be installed and configured with appropriate credentials.<br />

The credentials and other Azure details provided in the Terraform script must be valid.<br />

The script requires appropriate access permissions to create, modify, or destroy resources on Azure.<br />

Infrastructure:<br />

The script assumes the existence of certain resources (like the virtual network, subnet, and resource group) in the Azure environment. These resources should be present and correctly configured.<br />

The host(s) where MongoDB is to be installed should be accessible via SSH using the credentials provided in the script.<br />

You should have an available set of virtual machines (VMs) or have the capacity to create new VMs in your Azure environment.<br />

Ansible:<br />

Ansible should be able to communicate with the target hosts. Ensure that the target hosts are accessible via SSH, and that Ansible has the appropriate SSH key or login credentials.<br />

The ansible inventory file should be configured correctly.<br />

Remember to replace any placeholder values in the scripts (like Azure client_id, client_secret, tenant_id, subscription_id, admin usernames, passwords, ssh keys, etc.) with your actual values.<br />

Multiple options can be selected.<br />
