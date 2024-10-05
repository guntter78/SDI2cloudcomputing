#!/bin/bash

echo "Voer het aantal VMs in:"
read num_vms
echo "Voer de beginnende VM ID in:"
read vmid
echo "Voer de VM naam prefix in:"
read vmname
echo "Voer het laatste octet van het server IP in (start octet):"
read last_octet

# Basisinstellingen
cores=2
memory=2048
disk_size="50G"  
storage="DrivePool"  
bridge="vmbr0"
gw="10.24.36.1"
dns="8.8.8.8"
start_wait_time=20
iso_file="/var/lib/vz/template/iso/ubuntu-24.04.1-live-server-amd64.iso"  
key_dir="/root/vm_keys"

# Maak de map aan om sleutels op te slaan als die niet bestaat
mkdir -p $key_dir

# Loop om het opgegeven aantal VMs aan te maken
for ((i=0; i<num_vms; i++)); do
    id=$((vmid + i))
    ip="10.24.36.$((last_octet + i))/24"
    hostname="${vmname}${i}"

    # Controleer of de VM al bestaat
    if qm status $id &> /dev/null; then
        echo "VM met ID $id bestaat al. Sla over."
        continue
    fi

    echo "VM $id wordt aangemaakt met IP $ip en hostname $hostname"

    qm create $id \
      --name $hostname \
      --memory $memory \
      --cores $cores \
      --net0 virtio,bridge=$bridge \
      --scsihw virtio-scsi-pci \
      --boot c \
      --bootdisk scsi0 \
      --ostype l26

    # Installatie cd, schijf en ip
    qm set $id --cdrom $iso_file
    rbd create ${storage}/vm-${id}-disk-0 --size ${disk_size}
    qm set $id --scsi0 ${storage}:vm-${id}-disk-0
    qm set $id --ipconfig0 ip=$ip,gw=$gw

    # Start de VM
    qm start $id && echo "VM $id is gestart."

    echo "Wachten op het opstarten van de VM..."
    sleep $start_wait_time

done
