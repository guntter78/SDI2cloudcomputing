#!/bin/bash

echo "Enter the number of VMs:"
read num_vms
echo "Enter the starting VM ID for the new VMs:"
read start_vmid
echo "Enter the VM name prefix for the new VMs (use only letters, numbers, and dashes):"
read vmname
echo "Enter the last octet of the server IP (starting octet):"
read last_octet
echo "Enter the destination node where the new VMs will be created:"
read dest_node
echo "Voer het IP-adres van de monitoring server in:"
read monitor_ip

# Basisinstellingen
source_vmid=100  # De template VM ID (ubuntutemplate0)
source_node="vm1360"
old_ip="10.24.36.100"
ssh_key_path="~/.ssh/id_rsa_ubuntu_vm"

# Nodes waar de SSH-sleutel naar gekopieerd moet worden (gebruik IP-adressen)
cluster_nodes=("vm1360" "vm1361" "vm1362") 

# Loop om het opgegeven aantal VM's aan te maken
for ((i=0; i<num_vms; i++)); do
    new_vmid=$((start_vmid + i))
    new_ip="10.24.36.$((last_octet + i))"
    new_name="${vmname}${new_vmid}"

    echo "Cloning VM ${source_vmid} (template) from ${source_node} to ${dest_node} with name ${new_name} and IP ${new_ip}"
    qm clone ${source_vmid} ${new_vmid} --name ${new_name} --full --target ${dest_node} --storage drivepool
    ssh ${dest_node} "qm start ${new_vmid}"
    
    echo "Waiting for VM ${new_vmid} to fully boot up (2 minutes)..."
    sleep 120

    # Connect met de gekloonde VM en pas settings aan
    echo "Connecting to the cloned VM using the old IP address (${old_ip}) with user crmadmin and SSH key ${ssh_key_path}"

    # Update de netplan configuratie met het nieuwe IP-adres
    echo "Updating the IP address to ${new_ip} in /etc/netplan/50-cloud-init.yaml"
    ssh -i ${ssh_key_path} rudy@${old_ip} "sudo sed -i 's/  - 10.24.36\.[0-9]\{1,3\}\/24/  - ${new_ip}\/24/' /etc/netplan/50-cloud-init.yaml"
    
    # Wijzig de hostname
    echo "Changing the hostname to ${new_name}"
    ssh -i ${ssh_key_path} rudy@${old_ip} "sudo hostnamectl set-hostname ${new_name}"
    ssh -i ${ssh_key_path} rudy@${old_ip} "sudo hostnamectl set-hostname ${new_name} --pretty"
    
    # Update het /etc/hosts bestand met de nieuwe hostname
    echo "Updating /etc/hosts with the new hostname"
    ssh -i ${ssh_key_path} rudy@${old_ip} "sudo sed -i 's/127.0.1.1.*/127.0.1.1 ${new_name}/' /etc/hosts"
    
    # Voeg de hostname toe aan het /etc/hostname bestand
    echo "Adding the new hostname to /etc/hostname"
    ssh -i ${ssh_key_path} rudy@${old_ip} "echo '${new_name}' | sudo tee /etc/hostname"
    
    # Reset de VM zodat de configuratie van kracht wordt
    ssh ${dest_node} "qm reset ${new_vmid}"
    
    echo "New hostname and IP address applied for VM ${new_vmid}, Wait for 120 seconds"
    sleep 120

    ssh ${dest_node} "qm start ${new_vmid}"
    # Git-repository klonen en het script uitvoeren
    echo "Cloning GitHub repository and executing the script"
    ssh -i ${ssh_key_path} rudy@${new_ip} "sudo apt-get install git"
    ssh -i ${ssh_key_path} rudy@${new_ip} "sudo apt-get install ansible"
    ssh -i ${ssh_key_path} rudy@${new_ip} "git clone https://github.com/guntter78/SDI2cloudcomputing.git"
    ssh -i ${ssh_key_path} rudy@${new_ip} "sudo bash /SDI2cloudcomputing/portfolio1/crmvm.sh"

    # Nieuwe gebruiker aanmaken en SSH-sleutel genereren
    new_user="user_${new_name}"
    new_ssh_key_path="~/.ssh/sshkey_${new_name}"

    echo "Creating new user ${new_user} and generating SSH key..."
    ssh -i ${ssh_key_path} crmadmin@${new_ip} << EOF
        sudo adduser --disabled-password --gecos "" ${new_user}
        sudo mkdir -p /home/${new_user}/.ssh
        sudo chmod 700 /home/${new_user}/.ssh
EOF

    # Genereer een nieuwe SSH-sleutel voor de nieuwe gebruiker
    ssh-keygen -t rsa -b 2048 -f ${new_ssh_key_path} -N "" -C "${new_name}"
    
    # Voeg de nieuwe sleutel toe aan de VM en geef de juiste permissies
    ssh -i ${ssh_key_path} crmadmin@${new_ip} "echo '$(cat ${new_ssh_key_path}.pub)' | sudo tee /home/${new_user}/.ssh/authorized_keys"
    ssh -i ${ssh_key_path} crmadmin@${new_ip} "sudo chmod 600 /home/${new_user}/.ssh/authorized_keys"
    ssh -i ${ssh_key_path} crmadmin@${new_ip} "sudo chown -R ${new_user}:${new_user} /home/${new_user}/.ssh"
    
    # Distribute the SSH key naar andere nodes
    echo "Distributing the new SSH key for user ${new_user} to other nodes in the cluster..."
    for node in "${cluster_nodes[@]}"; do
        scp "${new_ssh_key_path}" root@${node}:/home/${new_user}/.ssh/
        scp "${new_ssh_key_path}.pub" root@${node}:/home/${new_user}/.ssh/
    done

    echo "SSH key distribution completed for VM ${new_vmid} and user ${new_user}"

    # Voeg de VM toe aan de CRM HA groep
    echo "Adding VM ${new_vmid} to HA group 'CRMHA'"  # Verwijder de spatie in de HA-groepnaam
    ha-manager add vm:${new_vmid} --group 'CRMHA'

    # Zet de HA status naar 'started'
    echo "Setting HA status to 'started' for VM ${new_vmid}"
    ha-manager set vm:${new_vmid} --state started

    sleep 10
done
