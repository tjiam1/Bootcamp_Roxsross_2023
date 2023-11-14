#! /bin/bash

#variable
VALOR1=$1
VALOR2=$2

if [ -d prueba ] ;
then
	echo "esto es un directorio"
else
	echo "no existe"
fi

#echo "Este es mi primer script de variable $VALOR1"
#mkdir hola
#touch hola/prueba.txt
#echo "fin de script $VALOR2"
