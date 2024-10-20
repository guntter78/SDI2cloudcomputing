# Portfolio 2

## Opdracht 1
In Portfolio 2 wordt de Docker-tutorial van Simplilearn behandeld. Hieronder een overzicht van de taken en de bijbehorende scripts:

### Lesson 4
De automatische installatie van een Ubuntu host met Docker op specifieke of alle Proxmox nodes. Dit gebeurt via de volgende scripts:
- **copyvmdockerselectnode.sh**: Installeert Docker op geselecteerde nodes.
- **copydockernodes.sh**: Installeert Docker op alle nodes en creëert automatisch een x aantal VMs met Docker.

Bij het uitvoeren van deze scripts worden Docker Compose en een Docker Swarm automatisch aangemaakt.

### Lesson 7
Bouw een Docker-image met een Dockerfile en creëer een nieuwe container op elke Docker-instantie binnen het Proxmox cluster. Dit wordt uitgevoerd met het script **dockerimage.sh**.

### Lesson 8
Installeer Docker Compose op alle Docker-instanties binnen het Proxmox cluster. Dit gebeurt met het script **dockercompose.sh**. Docker Compose wordt automatisch geïnstalleerd bij het uitvoeren van de scripts uit Lesson 4.

### Lesson 9
Creëer geautomatiseerd Docker Swarms op alle Docker-omgevingen in het Proxmox cluster. Dit wordt gedaan met het script **createswarm.sh**, dat ook automatisch wordt aangemaakt bij het uitvoeren van de scripts uit Lesson 4.

De opname van deze opdracht staat op youtube:
https://youtu.be/IKRjnWlnRDo

### Lesson 10
Voer basis Docker-netwerkcommando's uit met het script **basicnetworking.sh**. Dit script voert elk commando één voor één uit.

## Opdracht 2
In deze opdracht worden twee MySQL- of webservers opgezet met Redis, waarbij elke server in een apart subnet wordt geplaatst. De scripts voor deze taak bevinden zich in de map **mysqlcontainerdocker**, waar elke VM een eigen script heeft om twee MySQL-webservers op te zetten, elk met een eigen subnet.

Om de opdracht volledig af te ronden, moet de gebruiker het bash-script in de map **iproute** handmatig uitvoeren in de Proxmox-omgeving om de subnetten correct te configureren.

**Korte inlichting waarom meerdere subnetten kunnen aanmaken in Docker handig is:**
Er meerdere reden waarom verschillende subnetten maken handig zou zijn.
Allereerst biedt het de mogelijkheid om meer IP-adressen aan containers toe te wijzen, omdat je per container kunt specificeren tot welk subnet ze behoren. Dit zorgt voor meer flexibiliteit in de netwerkconfiguratie. Ten tweede kunnen containers op verschillende subnetten niet direct met elkaar communiceren, wat zorgt voor isolatie tussen containers. Dit verhoogt de beveiliging, omdat gevoelige containers afgeschermd kunnen worden van de rest van het netwerk.

## Opdracht 3
### Deel 1.
De bash-script bevindt zich in het mapje **composeopdracht3.1** en de screenshots in **screenshotopdracht.31**.

**Wat doet een Reverse proxy:**
Een reverse proxy is een tussenstation dat inkomende verzoeken van clients ontvangt en doorstuurt naar servers aan de achterkant. Dit heeft een paar voordelen, zoals load balancing, wat betekent dat het verkeer wordt verdeeld over meerdere servers, en beveiliging, omdat de proxy de echte serverdetails afschermt. In mijn geval zorgt Traefik ervoor dat het verkeer naar de juiste 'whoami' containers gaat en dat de verzoeken verdeeld worden over meerdere containers (load balancing).

### Deel 2
Voor deze opdracht heb ik gekozen voor een tutorial van Mazen Ramadan op de website:  
https://dev.to/mazenr/how-to-implement-a-load-balancer-using-nginx-docker-4g73

De stappen die ik heb gevolgd, beginnen bij "Implement Nginx Load Balancer". Hierin worden drie mappen aangemaakt: **app1**, **app2**, en **nginx**. Vervolgens moet in de app-mappen een **app.py** bestand worden aangemaakt met de gegeven informatie uit de tutorial. Ook wordt een Dockerfile aangemaakt om een Docker-container met Flask te deployen. Deze stap wordt herhaald voor **app2**.

In de map **nginx** wordt een configuratiebestand aangemaakt waarin de load balancer wordt gedefinieerd. Deze configuratie maakt gebruik van het "round robin"-mechanisme. Ook wordt hier een Dockerfile aangemaakt.

Als laatste stap moet er een **docker-compose.yml** bestand worden aangemaakt, buiten de mappen app1, app2 en nginx. In dit bestand worden services gedefinieerd zoals **app1** met daarin build instructies en poorten.

Nadat alle stappen zijn voltooid, kan het commando `sudo docker-compose up --build -d` worden uitgevoerd om de containers te starten. Zorg ervoor dat je dit commando uitvoert met `--build -d`, anders kunnen er mogelijk bestanden ontbreken of foutmeldingen optreden.
