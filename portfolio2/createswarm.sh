#!/bin/bash

# Stap 1: Controleer of de node al in een Swarm zit en verlaat de Swarm indien nodig
if docker info | grep -q "Swarm: active"; then
    echo "This node is already part of a Swarm. Leaving the current Swarm..."
    sudo docker swarm leave --force

    if [ $? -eq 0 ]; then
        echo "Successfully left the Swarm."
    else
        echo "An error occurred while leaving the Swarm."
        exit 1
    fi
else
    echo "This node is not part of any Swarm. Proceeding to initialize a new Swarm."
fi

# Stap 2: Haal het IP-adres van de huidige VM op
ip_address=$(hostname -I | awk '{print $1}')
echo "Initializing Docker Swarm on $ip_address..."

# Stap 3: Initialiseer Docker Swarm op deze VM als manager
sudo docker swarm init --advertise-addr $ip_address

# Controleer of de Swarm correct is geïnitialiseerd
if [ $? -eq 0 ]; then
    echo "Swarm successfully initialized on $ip_address. This VM is now the manager."
else
    echo "An error occurred while initializing the Swarm."
    exit 1
fi

# Stap 4: Toon de status van de nodes in deze Swarm (zou alleen de manager moeten zijn)
sudo docker node ls

# Stap 5: Voeg een service toe aan de Swarm
echo "Deploying HelloWorld service on the Swarm..."
sudo docker service create --name HelloWorld alpine ping docker.com

# Stap 6: Controleer de status van de services
echo "Listing all Docker services in the Swarm:"
sudo docker service ls

echo "Swarm setup completed on $ip_address!"
