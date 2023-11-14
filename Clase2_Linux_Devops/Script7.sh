#!/bin/bash

REPO="devops-static-web"

echo "===================="

apt-get update 

echo "El Servidor está actualizado" 

if dpkg -l | grep -q apache2 ;
# alternativa if dpkg -s apache2 > /dev/null 2>&1; then
then
    echo "Ya está instalado"
else 
    echo "instalando paquete apache2"
        apt install apache2 -y 
        systemctl start apach2
        systemctl enable apache2 
fi 

if [ -d "$REPO" ] ; 
then 
    echo "LA carpeta "$REPO" existe"
else
    git clone -b devops-mariobros https://github.com/roxsross/$REPO.git
fi

echo "Instalando Web"
sleep 1

sudo cp -R $REPO/* /var/www/html