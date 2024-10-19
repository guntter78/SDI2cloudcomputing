# SDI Cloud Computing Portfolio

Welkom bij mijn repository voor de SDI Cloud Computing opdrachten. Deze repository bevat twee portfolio's, elk met verschillende opdrachten waarin Proxmox, Ansible, Docker, en netwerkconfiguratie centraal staan.

## Portfolio 1

In deze portfolio bevinden zich vier bash-scripts en zes Ansible-playbooks die worden gebruikt voor het automatiseren van de cloud computing omgeving met behulp van Proxmox en Ansible. De volgende taken worden uitgevoerd:

- Automatiseren van containercreatie met WordPress.
- Aanmaken van een VM met CRM-software.
- Configureren van Zabbix monitoring voor zowel de containers als de CRM-VM.

De bash-scripts zorgen voor de uitvoering van deze taken, terwijl de Ansible-playbooks worden gebruikt voor de configuratie en installatie van de applicaties.

## Portfolio 2

In deze portfolio worden verschillende Docker-opdrachten uitgevoerd, gebaseerd op de Docker-tutorial van Simplilearn. De volgende taken worden uitgevoerd:

- Automatische installatie van een Ubuntu host met Docker op specifieke of alle Proxmox nodes.
- Creëren van Docker-images met Dockerfiles en het aanmaken van containers.
- Installeren van Docker Compose op alle Docker-instanties binnen het cluster.
- Creëren van Docker Swarms op de Docker-omgevingen.


In **Opdracht 2** worden twee MySQL-servers, waarbij elke server in een apart subnet wordt geplaatst. De scripts voor deze taak bevinden zich in de map **mysqlcontainerdocker**, waar elke VM een eigen script heeft om twee MySQL-webservers op te zetten, elk met een eigen subnet. Om de subnetten correct te configureren, moet de gebruiker het script in de map **iproute** handmatig uitvoeren in de Proxmox-omgeving.
