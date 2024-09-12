#!/bin/bash

# Переменные
CONTAINER_NAME="unifi-controller"
DATA_DIR="/docker/unifi-controller"
IMAGE_NAME="jacobalberty/unifi:v5.14"

# Создаем каталог для данных, если его еще нет
if [ ! -d "$DATA_DIR" ]; then
  echo "Создаем каталог для хранения данных: $DATA_DIR"
  sudo mkdir -p "$DATA_DIR"
fi

# Проверяем, установлен ли Docker
if ! [ -x "$(command -v docker)" ]; then
  echo "Ошибка: Docker не установлен. Устанавливаем Docker..."
  sudo apt update
  sudo apt install -y docker.io
  sudo systemctl enable --now docker
fi

# Проверяем, существует ли уже контейнер с таким именем
if [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "Контейнер с именем $CONTAINER_NAME уже существует. Удаляем его..."
  sudo docker stop $CONTAINER_NAME
  sudo docker rm $CONTAINER_NAME
fi

# Запуск контейнера UniFi с сохранением данных
echo "Запускаем UniFi Controller в Docker..."
sudo docker run -d \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 3478:3478/udp \
  -p 10001:10001/udp \
  -p 1900:1900 \
  -p 8880:8880 \
  -p 6789:6789 \
  -p 5514:5514 \
  -v "$DATA_DIR:/unifi" \
  $IMAGE_NAME

echo "UniFi Controller успешно запущен. Доступ к интерфейсу по адресу https://<IP-адрес>:8443"
