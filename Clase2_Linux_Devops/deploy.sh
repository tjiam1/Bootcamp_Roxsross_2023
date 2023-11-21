#!/bin/bash -x
#Variable
repo="bootcamp-devops-2023"
USERID=$(id -u)
config_file="/etc/apache2/mods-enabled/dir.conf"
HTTP_STATUS=$(curl -Is "http://localhost/info.php" | head -n 1)
#DB_PASS="codepass"
DB_PASS=$1
# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"
# Configura el token de acceso de tu bot de Discord
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"
#colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'


# Verificacion de usuario
if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${LRED}Error, correr con usuario ROOT${NC}"
    exit
fi

#### STAGE 1: [Init] ####

echo "====================================="
echo "Stage 1, inicializando web"

###### 1. Actualizar server ######

apt-get update
echo -e "\n${LGREEN}El Servidor se encuentra Actualizado ...${NC}"

###### 2. Valido instalacion de git ######

echo -e "\n${LBLUE}Validamos la instalación de Git...${NC}"

if dpkg -s git > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Git se encuentra instalado ...${NC}"
else
    echo -e "\n${LYELLOW}Instalando GIT ...${NC}"
    apt install -y git
fi

###### 3.  Valido instalación base de datos Maria DB ######

echo -e "\n${LBLUE}Comienza la instalación de Maria DB...${NC}"

if dpkg -s mariadb-server > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Maria DB se encuentra instalado ...${NC}"
else
    echo -e "\n${LYELLOW}Instalando MARIA DB ...${NC}"
    apt install -y mariadb-server
    echo -e "\n${LBLUE}Iniciamos y habilitamos Maria DB ...${NC}"
    systemctl start mariadb
    systemctl enable mariadb
fi

#### Validamos que Maria DB esté iniciado ####

echo -e "\n${LBLUE}Validamos el estado de Maria DB...${NC}"
if systemctl status mariadb |grep active > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Maria DB se encuentra iniciado ...${NC}"
else
    echo -e "\n${LBLUE}Iniciamos y habilitamos Maria DB ...${NC}"
    systemctl start mariadb
    systemctl enable mariadb
fi


###### 4. Valido instalcion apache [WEB] ######

echo -e "\n${LBLUE}Comienza la instalación del apache2...${NC}"

if dpkg -s apache2 > /dev/null 2>&1; then
    echo -e "\n${LBLUE}El Apache2 se encuentra instalado ...${NC}"
else
    echo -e "\n\e[92mInstalando Apache2 ...\033[0m\n"
    apt install -y apache2

###Iniciando apache###
    echo -e "\n\e[92mIniciando apache2 ...\033[0m\n"
    systemctl start apache2
    systemctl enable apache2
fi

#### Validamos que Apache2 esté iniciado ####

echo -e "\n${LBLUE}Validamos el estado del apache2...${NC}"
if systemctl status apache2 |grep active > /dev/null 2>&1; then
    echo -e "\n${LBLUE}Apache2 se encuentra iniciado ...${NC}"
else
    echo -e "\n${LBLUE}Iniciamos y habilitamos Apache2 ...${NC}"
    systemctl start apache2
    systemctl enable apache2
fi


###### 5. Valido instalcion PHP ######

if dpkg -s php > /dev/null 2>&1; then
    echo -e "\n${LBLUE}PHP se encuentra instalado ...${NC}"
    php -v
else
    echo -e "${BLUE}Instalando y Configurando php...${NC}"
    apt install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
    php -v
fi


###Finalizando instalacion
echo -e "${LGREEN}Instalación finalizada${NC}"


####-------------------------------------------------------------####

#### STAGE 2: [Build] ####

echo "====================================="
echo "Stage 2, construimos nuestra web"

echo -e "\n${LBLUE}Validamos y clonamos el repositorio...${NC}"
cd /mnt/c/Users/Lenovo/Documents/Tomi/Proyectos/Bootcamp_Roxsross_2023/Clase2_Linux_Devops

if [ -d "$repo" ]; then
    echo -e "\n${LBLUE}La carpeta $repo existe ...${NC}"
    git pull https://github.com/roxsross/$repo.git 
    git checkout clase2-linux-bash

else
    echo -e "\n${LBLUE}La carpeta $repo no existe, entonces clonamos el repositorio${NC}"
    sleep 1
    git clone -b clase2-linux-bash https://github.com/roxsross/$repo.git 
fi

echo -e "\n${LYELLOW}Instalando WEB ...${NC}"

### movemos el index.html ###

mv /var/www/html/index.html /var/www/html/index.html.bkp
cp -r $repo/app-295devops-travel/* /var/www/html
sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
echo "====================================="
### reload
systemctl reload apache2


### Configuramos base de datos Maria DB ###

echo -e "\n${LBLUE}Configurando base de datos ...${NC}"
mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;
"

#ejecutar script
echo -e "\n${LBLUE}Ejecutando el script SQL 'devopstravel.sql' ...${NC}"

mysql < database/devopstravel.sql

mysql -e "
USE devopstravel;
SHOW TABLES;
"

echo -e "${LGREEN}Configuracion completada${NC}"

#### STAGE 3: [Build] ####

echo "====================================="
echo "Stage 3, Deploy"

#### Configuramos apache 2####

echo -e "\n${LBLUE}Configuramos apache2...${NC}"

cp "$config_file"  "$config_file.backup"
sed -i 's/DirectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' "$config_file"
#systemctl reload apache2

echo -e "\n${LBLUE}Reemplazando la pass ...${NC}"

cd bootcamp-devops-2023/app-295devops-travel/
#sudo sed -i 's/""/'${DB_PASS}'/g' /var/www/html/config.php
sed -i 's/$dbPassword = "";/$dbPassword = "'$DB_PASS'";/g' /var/www/html/config.php

echo -e "\n${LBLUE}Reiniciando apache2 ...${NC}"

systemctl reload apache2
cat /var/www/html/config.php


echo -e "\n${LBLUE}Testeaamos la app ...${NC}"

if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
    echo -e "\n${LGREEN}El sitio funciona correctamente.${NC}"
else
    echo -e "\n${LRED}Error: El sitio no funciona como se esperaba.${NC}"
    exit
fi


echo -e "${LGREEN}Deploy completado correctamente!${NC}"

#### STAGE 4: [Notify] ####

echo "====================================="
echo "Stage 4, Notify"

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
    # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"
