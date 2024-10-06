# SDI2 Cloud Computing

Welkom bij de repository van SDI2 Cloud Computing!

In deze repository bevinden zich vier bash-scripts en zes Ansible-playbooks die gebruikt worden voor het opzetten van een cloud computing omgeving met behulp van Proxmox en Ansible. Hieronder vind je een uitleg over de inhoud en werking van de scripts en playbooks.

## Bash-scripts

### 1. `makecontainer6.sh`
Dit script automatiseert het proces van het aanmaken en configureren van containers in Proxmox. Het script vraagt om de volgende variabelen:
- **Aantal containers**: Het aantal containers dat moet worden aangemaakt.
- **Proxmox ID**: Het unieke ID voor elke container.
- **Servernaam**: De naam van de container.
- **Laatste octet van het IP-bereik**: Het IP-adres dat aan de container wordt toegewezen.
- **Server IP voor monitoring**: Het IP-adres van de server waar de logs naartoe verzonden moeten worden.

Zodra deze variabelen zijn ingevoerd, maakt het script containers aan, inclusief het toewijzen van IP-adressen en het voorbereiden van de Ansible-playbook. Daarna installeert het:
- **WordPress** op elke container.
- **Zabbix-agent** voor logverzending naar de monitor server.
- **Firewall-configuratie** om de nodige services te beveiligen.

### 2. `makevm.sh`
Dit script creëert een aantal servers (VM's) in Proxmox met de juiste specificaties zoals CPU, RAM en opslagruimte. Je kunt zelf bepalen hoeveel servers er aangemaakt moeten worden, en het script automatiseert de configuratie van deze VM's binnen Proxmox.

### 3. `copy.vm`
Dit script kopieert een aantal bestaande servers binnen Proxmox, vergelijkbaar met het aanmaken van containers, maar met een belangrijk verschil: in plaats van WordPress, worden deze VM's geconfigureerd om CRM-software te draaien. Net zoals bij de container-setup, vraagt het script naar het aantal VM's en de benodigde specificaties.

### 4. `crm.sh`
Dit script wordt uitgevoerd nadat `copy.vm` klaar is. In dit script worden de belangrijke modules geïnstalleerd die nodig zijn om de CRM-software te laten draaien op de VM's. Daarnaast wordt de **Zabbix-agent** geconfigureerd om verbinding te maken met een aparte monitoring server.

## Ansible Playbooks

In de map `Ansible` bevinden zich zes Ansible-playbooks:
- **1 oude playbook**: `wordpress_playbook.yml.old` (overbodig en niet meer in gebruik).
- **5 werkende playbooks**:
  
  ### 1. `container_firewall_playbook.yml`
  Dit playbook configureert de firewall op de containers door belangrijke poorten te allowen en onbelangrijke poorten te blokkeren.

  ### 2. `crm_espo_playbook.yml`
  Dit playbook installeert de EspoCRM-software met alle benodigde modules om EspoCRM correct te laten draaien.

  ### 3. `wordpress_playbook.yml`
  Dit playbook installeert WordPress met alle belangrijke modules die nodig zijn om WordPress functioneel te maken.

  ### 4. `zabbix_agent_playbook.yml`
  Dit playbook installeert en configureert de Zabbix-agent op de containers of VM's. Het script koppelt de IP-adressen van de containers/VM's aan de Zabbix-server en voegt metadata toe (zoals 'WordPress' of 'CRM'). Op basis van deze metadata worden de servers automatisch in de juiste groep geplaatst met de bijbehorende templates op de Zabbix-server.

  ### 5. `zabbix_server_playbook.yml`
  Dit playbook configureert een server om als Zabbix-server te fungeren, waar alle logs naartoe worden gestuurd. Het playbook is nog niet volledig geautomatiseerd omdat er handmatige stappen nodig zijn om de database te koppelen via de Zabbix-server website en ervoor te zorgen dat de Zabbix-clients in de juiste groep worden geplaatst.

## Huidige status
De laatste twee bash-scripts (`copy.vm` en `crm.sh`) en het Zabbix-server playbook zijn nog niet volledig getest, omdat de Proxmox-server helaas meerdere keren is uitgeschakeld. Deze storing is al drie keer voorgekomen, waarvan twee keer op 5-10-2024: één keer in de ochtend en één keer rond het avondeten.

## Gebruik

1. Clone deze repository:
    ```bash
    git clone git@github.com:guntter78/SDI2cloudcomputing.git
    ```

2. Voer het bash-script uit om de containers of VM's aan te maken en te configureren:
    - Voor containers: 
      ```bash
      ./makecontainer6.sh
      ```
    - Voor VM's:
      ```bash
      ./makevm.sh
      ```

3. Nadat de VM's zijn aangemaakt, voer `crm.sh` uit om de CRM-software en de Zabbix-client te installeren:
    ```bash
    ./crm.sh
    ```

4. Volg de prompts in de scripts om het aantal servers, Proxmox ID's, servernamen, IP-adressen en monitoring server IP in te vullen.

## Toekomstige uitbreidingen
- Volledige test van de VM-gerelateerde scripts zodra de Proxmox-server weer beschikbaar is.
- Volledige configuratie van de Zabbix-server via Ansible.
- Verbeterde monitoring en logging functionaliteit.

Voor volledige geschiedenis van het bouwen van de script zie je op mijn github bij de commits.
https://github.com/guntter78/SDI2cloudcomputing
