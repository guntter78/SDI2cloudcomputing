#!/bin/bash

# Basisinstellingen
id=555
arch_type=amd64
os_type=ubuntu
hostname=testmachine
cores=1
memory=8000
swap=8000
storage="DrivePool"  # Update this if you are using a different storage.
password="hiereengoedwachtwoord;)"
net0_name="e1000"
bridge="vmbr0"
gw="192.168.168.1"
ip="192.168.168.25/24"
type="veth"
start_wait_time=1

# Volledig pad naar het template-bestand
template_path="/var/lib/vz/template/cache/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

# Container aanmaken en starten
pct create $id $template_path \
  --arch $arch_type \
  --ostype $os_type \
  --hostname $hostname \
  --cores $cores \
  --memory $memory \
  --swap $swap \
  --storage $storage \
  --password $password \
  --net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,type=$type \
  && echo "Container is successfully created and configured."

# Container starten
pct start $id && echo "Container is starting."

# Wachten op de container om te starten
sleep $start_wait_time && echo "Container is now running."
