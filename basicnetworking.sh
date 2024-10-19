#!/bin/bash

# Basis Docker Netwerkcommando's
echo "List of available Docker networks:"
docker network ls
echo ""

echo "List of available Docker containers:"
docker container ps -a
echo ""

# Functie om te controleren of de opgegeven containernaam geldig is
function check_container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^$1$"
}

# Vraag naar de containernaam en controleer of deze geldig is
while true; do
    echo "Enter the container name you want to connect to the network:"
    read container_name

    # Controleer of de container bestaat
    if check_container_exists "$container_name"; then
        echo "Container ${container_name} found."
        break
    else
        echo "Error: No such container: ${container_name}. Please try again."
    fi
done

# Controleer of het netwerk bestaat
network_name="multi-host-network"
if ! docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
    echo "Network ${network_name} does not exist. Creating network..."
    
    # Maak een netwerk met een ander subnet, bijvoorbeeld 192.168.100.0/24
    docker network create --subnet=192.168.100.0/24 ${network_name}
    echo "Network ${network_name} created with subnet 192.168.100.0/24."
else
    echo "Network ${network_name} already exists, proceeding..."
fi

# Ontkoppel de container van het netwerk als deze al verbonden is
if docker inspect "$container_name" | grep -q "\"$network_name\""; then
    echo "Container is already connected to ${network_name}. Disconnecting..."
    docker network disconnect ${network_name} $container_name
    echo "Container disconnected from ${network_name}."
fi

# Vraag naar het netwerk IP
while true; do
    echo "Enter the last octet of the network IP"
    read last_octet

    # Controleer of de octet een geldig getal is tussen 2 en 254
    if [[ "$last_octet" -ge 2 && "$last_octet" -le 254 ]]; then
        new_ip="192.168.100.$((last_octet))"
        echo "IP address set to ${new_ip}."
        break
    else
        echo "Error: Invalid IP octet. Please enter a number between 2 and 254."
    fi
done

# Vraag naar een aliasnaam voor de container
echo "What will the container alias be called?"
read alias

# Verbind de container met het netwerk, wijs IP-adres en alias toe
echo "Connecting the container to the network, assigning IP address and alias..."
docker network connect --ip ${new_ip} --alias ${alias} ${network_name} $container_name
echo "Container connected with IP ${new_ip} and alias ${alias}."
echo ""
