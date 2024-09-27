#!/bin/bash

echo "Enter server ID"
read serverid
echo "Enter server name:"
read servername
echo "Enter laatste octet van het server IP:"
read last_octet


# Basisinstellingen
id=$serverid
arch_type=amd64
os_type=ubuntu
hostname=$servername
cores=1
memory=1024
swap=512
storage="DrivePool"
password="hiereengoedwachtwoord;)"
net0_name="eth4"
bridge="vmbr0"
gw="10.24.36.1"
ip="10.24.36.$last_octet/24"
dns="8.8.8.8"
type="veth"
start_wait_time=10

# Volledig pad naar het template-bestand
template_path="/var/lib/vz/template/cache/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

# Container aanmaken en starten
pct create $id $template_path \
  -arch $arch_type \
  -ostype $os_type \
  -hostname $hostname \
  -cores $cores \
  -memory $memory \
  -swap $swap \
  -storage $storage \
  -password $password \
  -net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,type=$type \
  && echo "Container is successfully created and configured."

# Container starten
pct start $id && echo "Container is starting."

# Wacht even tot de container volledig is opgestart
sleep $start_wait_time

# Zorg ervoor dat de eth0-interface actief is
pct exec $id -- ip link set $net0_name up
pct exec $id -- ip addr add $ip dev $net0_name

# Standaard netwerkconfiguratie instellen binnen de container
pct exec $id -- bash -c "echo 'nameserver $dns' > /etc/resolv.conf"
pct exec $id -- ip route add default via $gw

# Netwerkconfiguratie controleren en pingen naar de gateway
pct exec $id -- bash -c "ip a; ip route; ping -c 4 $gw"

pct exec $id -- apt-get update
pct exec $id -- apt-get install -y openssh-server sudo
pct exec $id -- systemctl enable ssh
pct exec $id -- systemctl start ssh

# Basis connectiviteit testen (DNS en internet)
pct exec $id -- ping -c 4 www.google.com
pct exec $id -- ping -c 4 8.8.8.8
