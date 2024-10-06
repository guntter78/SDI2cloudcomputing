#!/bin/bash

echo "Enter the number of VMs:"
read num_vms
echo "Enter the starting VM ID for the new VMs:"
read start_vmid
echo "Enter the VM name prefix for the new VMs (use only letters, numbers, and dashes):"
read vmname
echo "Enter the last octet of the server IP (starting octet):"
read last_octet

# Basisinstellingen
source_vmid=149  
old_ip="10.24.36.149"  

# SSH sleutels opslaan in deze directory
ssh_key_path="~/.ssh/149_rsa_vm"  

# Loop om het opgegeven aantal vm aan te maken
for ((i=0; i<num_vms; i++)); do
    new_vmid=$((start_vmid + i))
    new_ip="10.24.36.$((last_octet + i))"
    new_name="${vmname}${new_vmid}"

    echo "Cloning VM ${source_vmid} to VM ${new_vmid} with name ${new_name} and IP ${new_ip}"
    qm clone ${source_vmid} ${new_vmid} --name ${new_name} --full
    qm start ${new_vmid}
    echo "Waiting for VM ${new_vmid} to fully boot up (2 minutes)..."
    sleep 120

    # Connect met vm en pas settigns aan
    echo "Connecting to the cloned VM using the old IP address (${old_ip}) with user crmadmin and SSH key ${ssh_key_path}"
    echo "Updating the IP address to ${new_ip} in /etc/netplan/50-cloud-init.yaml"
    ssh -i ${ssh_key_path} crmadmin@${old_ip} "sudo sed -i 's/  - 10.24.36\.[0-9]\{1,3\}\/24/  - ${new_ip}\/24/' /etc/netplan/50-cloud-init.yaml"
    echo "Changing the hostname to ${new_name}"
    ssh -i ${ssh_key_path} crmadmin@${old_ip} "sudo hostnamectl set-hostname ${new_name}"
    echo "Updating /etc/hosts with the new hostname"
    ssh -i ${ssh_key_path} crmadmin@${old_ip} "sudo sed -i 's/127.0.1.1.*/127.0.1.1 ${new_name}/' /etc/hosts"
    echo "Adding the new hostname to /etc/hostname"
    ssh -i ${ssh_key_path} crmadmin@${old_ip} "echo '${new_name}' | sudo tee /etc/hostname"
    qm reset ${new_vmid}
    echo "New hostname and IP address applied for VM ${new_vmid}"

    sleep 10
done
