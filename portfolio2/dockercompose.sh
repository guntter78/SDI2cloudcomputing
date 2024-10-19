#!/bin/bash

# Download Docker Compose naar /usr/local/bin
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Maak Docker Compose uitvoerbaar
sudo chmod +x /usr/local/bin/docker-compose

# Controleer de versie van Docker Compose
docker-compose --version

echo "Docker Compose is successfully installed."
