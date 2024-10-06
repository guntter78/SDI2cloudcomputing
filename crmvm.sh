#!/bin/bash

# Definieer het pad naar de Ansible map
ANSIBLE_DIR="ansible"

# Zorg dat we in de Ansible map zitten
cd $ANSIBLE_DIR

# Check of de map bestaat
if [ ! -d "$ANSIBLE_DIR" ]; then
  echo "Map $ANSIBLE_DIR bestaat niet!"
  exit 1
fi

# Voer het crm_espo_playbook uit
echo "Voer crm_espo_playbook.yml uit..."
ansible-playbook -i localhost, crm_espo_playbook.yml

if [ $? -ne 0 ]; then
  echo "crm_espo_playbook.yml is mislukt!"
  exit 1
fi

# Voer het container_firewall_playbook uit
echo "Voer container_firewall_playbook.yml uit..."
ansible-playbook -i localhost, container_firewall_playbook.yml

if [ $? -ne 0 ]; then
  echo "container_firewall_playbook.yml is mislukt!"
  exit 1
fi

# Voer het zabbix_agent_playbook uit met host_metadata=crm
echo "Voer zabbix_agent_playbook.yml uit met host_metadata=crm..."
ansible-playbook -i localhost, zabbix_agent_playbook.yml --extra-vars "host_metadata=crm"

if [ $? -ne 0 ]; then
  echo "zabbix_agent_playbook.yml (crm) is mislukt!"
  exit 1
fi

echo "Alle playbooks zijn succesvol uitgevoerd!"
