#!/bin/bash
# Добавление скрипта в автозагрузку.
# sudo bash -c '(crontab -l 2>/dev/null; echo "@reboot /home/it/ZabbixServerDocker.sh") | crontab -'
# Автоустановка всего необходимого
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get install cron htop mc nload screenfetch net-tools traceroute docker.io -y

# Остановка всех работающих контейнеров
sudo docker stop $(sudo docker ps -q)

# Удаление всех контейнеров
sudo docker rm $(sudo docker ps -a -q)

# Удаление всех образов
sudo docker rmi $(sudo docker images -q)

# (Необязательно) Удаление всех зависимостей и томов (если нужно)
sudo docker system prune -a -f --volumes

#!/bin/bash

# Создание volume для данных MariaDB
docker volume create mariadb_data

# Запуск MariaDB сервера с использованием network host
docker run --network=host --name mariadb-server \
    -e MYSQL_ROOT_PASSWORD=D7W9FuXmFfPc \
    -e MYSQL_DATABASE=zabbix \
    -e MYSQL_USER=zabbix \
    -e MYSQL_PASSWORD=PJuT63EYh7SG \
    -v mariadb_data:/var/lib/mysql \
    -d mariadb:11.4

# Ожидание полного запуска MariaDB
echo "Ожидание запуска MariaDB..."
sleep 10

# Установка MariaDB клиента внутри контейнера MariaDB
docker exec mariadb-server apt-get update
docker exec mariadb-server apt-get install -y mariadb-client

# Настройка базы данных
echo "Настройка базы данных..."
docker exec mariadb-server mariadb -u root -pD7W9FuXmFfPc -e "
    ALTER DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
"

# Конвертация таблиц базы данных Zabbix в нужную кодировку и коллацию
echo "Конвертация таблиц в utf8 и utf8_bin ..."

# Получаем список таблиц
tables=$(docker exec mariadb-server mariadb -u root -pD7W9FuXmFfPc -N -e "
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'zabbix' AND TABLE_TYPE = 'BASE TABLE';
")

# Конвертируем таблицы по одной
for table in $tables; do
    echo "Конвертация таблицы $table ..."
    docker exec mariadb-server mariadb -u root -pD7W9FuXmFfPc -e "
        ALTER TABLE zabbix.$table CONVERT TO CHARACTER SET utf8 COLLATE utf8_bin;
    "
done

# Запуск сервера Zabbix с использованием network host
docker run --network=host --name zabbix-server-mysql \
    -e DB_SERVER_HOST="127.0.0.1" \
    -e MYSQL_USER="zabbix" \
    -e MYSQL_PASSWORD="PJuT63EYh7SG" \
    -e MYSQL_DATABASE="zabbix" \
    --init \
    -d zabbix/zabbix-server-mysql:alpine-latest

# Запуск веб-интерфейса Zabbix на Apache с использованием network host
docker run --network=host --name zabbix-frontend-apache \
    -e ZBX_SERVER_HOST="127.0.0.1" \
    -e DB_SERVER_HOST="127.0.0.1" \
    -e MYSQL_USER="zabbix" \
    -e MYSQL_PASSWORD="PJuT63EYh7SG" \
    -e MYSQL_DATABASE="zabbix" \
    -e PHP_TZ="Europe/Moscow" \
    -d zabbix/zabbix-web-apache-mysql:alpine-latest

# Запуск Zabbix агента с использованием network host
docker run --network=host --name zabbix-agent \
   -e ZBX_SERVER_HOST="127.0.0.1" \
   -d zabbix/zabbix-agent:ubuntu-latest

echo "Установка Zabbix завершена. Все контейнеры используют сеть хоста."

