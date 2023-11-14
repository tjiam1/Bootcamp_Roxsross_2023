#! /bin/bash

# Valido si está instalado el paquete git

#if dpkg -l |grep -q git ;
if dpkg -l |grep -q apache2 ;
then
	echo "este paquete ya está instalado"
else
	echo "Instalando paquete"
#	apt install git -y
	apt install apache2 -y
fi

