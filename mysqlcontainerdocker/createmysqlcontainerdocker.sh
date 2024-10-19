#!/bin/bash

# Verwijder bestaande containers als ze nog bestaan
echo "Removing existing containers..."
sudo docker rm -f mysql_server1 mysql_server2 test_client1 test_client2

# Verwijder bestaande netwerken
echo "Removing existing networks..."
sudo docker network rm mysql_net1 mysql_net2

# Creëer nieuwe Docker-netwerken (elk met een 192.168.x.x subnet)
echo "Creating new Docker networks..."
sudo docker network create --subnet=192.168.1.0/24 mysql_net1
sudo docker network create --subnet=192.168.2.0/24 mysql_net2

# Start de MySQL-containers in de nieuwe subnetten
echo "Starting MySQL containers..."
sudo docker run -d --name mysql_server1 --net mysql_net1 --ip 192.168.1.2 -e MYSQL_ROOT_PASSWORD=root mysql:5.7
sudo docker run -d --name mysql_server2 --net mysql_net2 --ip 192.168.2.2 -e MYSQL_ROOT_PASSWORD=root mysql:5.7

# Wacht tot de containers volledig zijn opgestart
echo "Waiting for MySQL containers to fully start..."
sleep 20

# Configureer MySQL bind-address
echo "Configuring MySQL bind-address..."
sudo docker exec -it mysql_server1 bash -c "echo '[mysqld]\nbind-address = 0.0.0.0' >> /etc/mysql/mysql.conf.d/mysqld.cnf"
sudo docker exec -it mysql_server2 bash -c "echo '[mysqld]\nbind-address = 0.0.0.0' >> /etc/mysql/mysql.conf.d/mysqld.cnf"

# Herstart de MySQL-servers om de configuratiewijzigingen toe te passen
echo "Restarting MySQL servers to apply configuration changes..."
sudo docker restart mysql_server1
sudo docker restart mysql_server2

# Wacht tot de servers weer zijn opgestart
echo "Waiting for MySQL to restart..."
sleep 20

# Start MySQL zonder rechten (skip grants) om root toegang te verlenen
echo "Temporarily disabling MySQL grants..."
sudo docker exec -d mysql_server1 bash -c "mysqld --skip-grant-tables &"
sudo docker exec -d mysql_server2 bash -c "mysqld --skip-grant-tables &"
sleep 10

# Verleen toegang voor externe verbindingen aan de root gebruiker
echo "Granting remote access to root user..."
sudo docker exec mysql_server1 mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"
sudo docker exec mysql_server2 mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"

# Herstart de MySQL-servers om de wijzigingen toe te passen
echo "Restarting MySQL servers..."
sudo docker restart mysql_server1
sudo docker restart mysql_server2

# Wacht tot de servers volledig zijn opgestart
echo "Waiting for MySQL to fully restart..."
sleep 20

# Start testcontainers in elk subnet om de connectiviteit te testen
echo "Starting test containers..."
sudo docker run -itd --name test_client1 --net mysql_net1 alpine sh
sudo docker run -itd --name test_client2 --net mysql_net2 alpine sh

# Installeer de MySQL-client in de testcontainers
echo "Installing MySQL client in test containers..."
sudo docker exec test_client1 apk add mysql-client
sudo docker exec test_client2 apk add mysql-client

# Test verbinding van test_client1 naar mysql_server1
echo "Testing connection from test_client1 to mysql_server1..."
sudo docker exec test_client1 mysql -h 192.168.1.2 -u root -proot -e "SHOW DATABASES;"

# Test verbinding van test_client2 naar mysql_server2
echo "Testing connection from test_client2 to mysql_server2..."
sudo docker exec test_client2 mysql -h 192.168.2.2 -u root -proot -e "SHOW DATABASES;"

# Test of MySQL op poort 3306 luistert in beide servers
echo "Testing if MySQL is listening on port 3306 in mysql_server1..."
sudo docker exec mysql_server1 netstat -tuln | grep 3306

echo "Testing if MySQL is listening on port 3306 in mysql_server2..."
sudo docker exec mysql_server2 netstat -tuln | grep 3306

