#!/bin/bash

# Voeg iptables-regels toe om verkeer tussen Proxmox en Docker-netwerken toe te staan
echo "Adding iptables rules..."
# Toestaan van verkeer tussen Proxmox en Docker netwerk 192.168.3.0/24
sudo iptables -A FORWARD -s 10.24.36.0/24 -d 192.168.3.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.3.0/24 -d 10.24.36.0/24 -j ACCEPT

# Toestaan van verkeer tussen Proxmox en Docker netwerk 192.168.4.0/24
sudo iptables -A FORWARD -s 10.24.36.0/24 -d 192.168.4.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.4.0/24 -d 10.24.36.0/24 -j ACCEPT

# Toestaan van verkeer vanuit de Docker-netwerken
sudo iptables -A FORWARD -s 192.168.3.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 192.168.3.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.4.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 192.168.4.0/24 -j ACCEPT

# Controleer of IP forwarding is ingeschakeld
echo "Checking if IP forwarding is enabled..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" -eq 0 ]; then
    echo "Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
else
    echo "IP forwarding is already enabled."
fi
