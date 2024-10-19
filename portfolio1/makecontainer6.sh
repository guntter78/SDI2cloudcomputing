#!/bin/bash

echo "Voer het aantal containers in:"
read num_containers
echo "Voer de beginnende server ID in:"
read serverid
echo "Voer de server naam prefix in:"
read servername
echo "Voer het laatste octet van het server IP in (start octet):"
read last_octet
echo "Voer het IP-adres van de monitoring server in:"
read monitor_ip

# Basisinstellingen
arch_type=amd64
os_type=ubuntu
cores=1
memory=1024
swap=512
storage="DrivePool"
password="hiereengoedwachtwoord;)"
bridge="vmbr0"
gw="10.24.36.1"
dns="8.8.8.8"
rate=50000
start_wait_time=20

# SSH sleutels opslaan in deze directory
ssh_base_path="/root/sshkeyscontainers"
mkdir -p $ssh_base_path

# Volledig pad naar het template-bestand
template_path="/var/lib/vz/template/cache/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

# Loop om het opgegeven aantal containers aan te maken
for ((i=0; i<num_containers; i++)); do
    id=$((serverid + i))
    ip="10.24.36.$((last_octet + i))/24"
    hostname="${servername}${i}"
    net0_name="eth$id"

    # Controleer of de container al bestaat
    if pct status $id &> /dev/null; then
        echo "Container met ID $id bestaat al. Sla over."
        continue
    fi

    echo "Container $id wordt aangemaakt met IP $ip en hostname $hostname"

    pct create $id $template_path \
      -arch $arch_type \
      -ostype $os_type \
      -hostname $hostname \
      -cores $cores \
      -memory $memory \
      -swap $swap \
      -storage $storage \
      -password $password \
      -net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,rate=$rate \
      && echo "Container $id is succesvol aangemaakt en geconfigureerd."

    # Container starten
    pct start $id && echo "Container $id is gestart."

    # Wacht even tot de container volledig is opgestart
    echo "Wachten op het opstarten van de container en SSH..."
    sleep $start_wait_time

    # Zorg ervoor dat de eth<ID>-interface actief is
    pct exec $id -- ip link set $net0_name up
    pct exec $id -- ip addr add $ip dev $net0_name

    # Standaard netwerkconfiguratie instellen binnen de container
    pct exec $id -- bash -c "echo 'nameserver $dns' > /etc/resolv.conf"
    pct exec $id -- ip route add default via $gw

    # Installeren van noodzakelijke pakketten en locale configureren
    pct exec $id -- apt-get update
    echo "Locale instellen in container $id"
    pct exec $id -- apt-get install -y locales
    pct exec $id -- locale-gen en_US.UTF-8
    pct exec $id -- update-locale LANG=en_US.UTF-8

    # Installeer overige pakketten zoals SSH en Git
    pct exec $id -- apt-get install -y openssh-server sudo git
    pct exec $id -- systemctl enable ssh
    pct exec $id -- systemctl start ssh
    pct set $id --features nesting=1

    # Installeer Ansible in de container
    echo "Ansible installeren op container $id..."
    pct exec $id -- apt-get install -y software-properties-common
    pct exec $id -- apt-add-repository --yes --update ppa:ansible/ansible
    pct exec $id -- apt-get install -y ansible

    # Clone de repository binnen de container nadat Ansible is geinstalleerd
    pct exec $id -- git clone https://github.com/guntter78/SDI2cloudcomputing.git /SDI2cloudcomputing
    if [ $? -ne 0 ]; then
        echo "Fout bij het klonen van de GitHub repository op container $id."
        continue
    fi

    # Voer het Ansible-playbook uit binnen de container met localhost als inventaris
    echo "Voer het Ansible playbook uit op container $id"
    pct exec $id -- ansible-playbook -i localhost, /SDI2cloudcomputing/portfolio1/ansible/wordpress_playbook.yml \
      && echo "WordPress installatie playbook uitgevoerd op container $id"

    # Voer het Zabbix-agent playbook uit, geef het monitor IP door als variabele
    echo "Voer het Zabbix-agent playbook uit op container $id"
    pct exec $id -- ansible-playbook -i localhost, /SDI2cloudcomputing/portfolio1/ansible/zabbix_agent_playbook.yml --extra-vars "zabbix_server_ip=$monitor_ip host_metadata=wordpresscontainer" \
      && echo "Zabbix-agent geinstalleerd op container $id"

    # Voer het firewall playbook uit op container $id
    echo "Voer het firewall playbook uit op container $id"
    pct exec $id -- ansible-playbook -i localhost, /SDI2cloudcomputing/portfolio1/ansible/container_firewall_playbook.yml \
      && echo "Firewall op container $id geïnstalleerd."

    # Unieke gebruikers met SSH-sleutels aanmaken in elke container
    for user_index in 1 2; do
        username="${servername}_user${user_index}_${i}"
        
        # Maak een gebruiker aan in de container
        pct exec $id -- useradd -m -s /bin/bash $username
        pct exec $id -- mkdir -p /home/$username/.ssh
        pct exec $id -- chmod 700 /home/$username/.ssh
        
        # Genereer een unieke SSH-sleutel voor de gebruiker
        ssh_key="${ssh_base_path}/${username}_container_${id}_id_rsa"
        ssh_pub_key="${ssh_key}.pub"
        ssh-keygen -t rsa -b 2048 -f $ssh_key -q -N ""
        
        # Kopieer de publieke sleutel naar de container
        pct exec $id -- bash -c "echo '$(cat ${ssh_pub_key})' > /home/$username/.ssh/authorized_keys"
        pct exec $id -- chmod 600 /home/$username/.ssh/authorized_keys
        pct exec $id -- chown -R $username:$username /home/$username/.ssh

        echo "Gebruiker $username is aangemaakt met SSH-toegang."
        echo "SSH-sleutels opgeslagen in $ssh_base_path voor $username."
    done

    # Apache service herstarten na herladen van systemd
    pct exec $id -- systemctl daemon-reload
    pct exec $id -- systemctl restart apache2
done
