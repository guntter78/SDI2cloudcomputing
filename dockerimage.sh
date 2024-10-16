#!/bin/bash

# Maak een directory aan voor de Dockerfile
mkdir -p ~/simplidocker
cd ~/simplidocker

# Schrijf de Dockerfile
cat <<EOF > Dockerfile
FROM ubuntu:18.04
MAINTAINER simplilearn
RUN apt-get update && apt-get install -y curl vim
CMD ["echo", "Welcome to Simplilearn"]
EOF

# Bouw het Docker-image
echo "Building Docker image..."
docker build -t simplilearn_image .

# Creëer en start de Docker-container
echo "Creating and starting Docker container..."
docker run --name simplilearn_container simplilearn_image

echo "Docker container is now running."
