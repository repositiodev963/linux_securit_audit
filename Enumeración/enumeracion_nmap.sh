#!/bin/bash
# Author: IBN (fb.com/DeDSec1)
# Este script realiza una enumeración básica de una red utilizando Nmap
# Se realizan los siguientes escaneos:
# 1. Escaneo de hosts activos
# 2. Escaneo de puertos comunes
# 3. Escaneo de todos los puertos
# 4. Detección de sistema operativo
# 5. Detección de versiones de servicios
# 6. Búsqueda de vulnerabilidades
# 7. Escaneo agresivo
# 8. Escaneo de puertos UDP

# Manejo de señales para controlar interrupciones
temp_option=""
trap 'echo "\n¿Deseas salir? Presiona 1 para salir o 2 para continuar."; read -p "Ingrese su opción: " choice; if [[ $choice == 1 ]]; then exit 0; else clear; fi' SIGINT SIGTERM

# Verificar dependencias
for cmd in curl jq nmap; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd no está instalado. Por favor, instálalo antes de continuar."
        exit 1
    fi
done

# Definir la ruta base para almacenar resultados
BASE_DIR="resultados"

# Verificar si la carpeta 'resultados' existe, si no, crearla
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR"
    echo "[+] Carpeta de resultados creada: $BASE_DIR"
else
    echo "[+] Usando el directorio existente: $BASE_DIR"
fi

# Solicitar la IP al inicio del script
read -p "Introduce la IP o subred (ej. 192.168.1.1 o 192.168.1.0/24): " TARGET

# Función para mostrar la barra de progreso
mostrar_progreso() {
    local duration=$1
    echo -n "[";
    for ((i=0; i<duration; i++)); do
        echo -n "#"
        sleep 1
    done
    echo "] Completado"
}

# Función para obtener la geolocalización de la IP
geolocalizar_ip() {
    GEO_INFO=$(curl -s http://ip-api.com/json/$TARGET | jq -r '.query, .country, .regionName, .city, .isp')
    if [ -z "$GEO_INFO" ]; then
        echo "Ubicación: No disponible" >> "$TXT_FILE"
    else
        echo "----------------------------------------------" >> "$TXT_FILE"
        echo "GEOLocalización de IP" >> "$TXT_FILE"
        echo "----------------------------------------------" >> "$TXT_FILE"
        echo "IP: $(echo "$GEO_INFO" | sed -n '1p')" >> "$TXT_FILE"
        echo "País: $(echo "$GEO_INFO" | sed -n '2p')" >> "$TXT_FILE"
        echo "Región: $(echo "$GEO_INFO" | sed -n '3p')" >> "$TXT_FILE"
        echo "Ciudad: $(echo "$GEO_INFO" | sed -n '4p')" >> "$TXT_FILE"
        echo "ISP: $(echo "$GEO_INFO" | sed -n '5p')" >> "$TXT_FILE"
    fi
}

# Función para realizar escaneos Nmap
ejecutar_nmap() {
    local scan_type=$1
    local nmap_args=$2

    TARGET_DIR="$BASE_DIR/$TARGET"
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        echo "[+] Carpeta creada para la IP: $TARGET_DIR"
    fi

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    TXT_FILE="$TARGET_DIR/${TIMESTAMP}_${TARGET}.txt"

    echo "=============================================" > "$TXT_FILE"
    echo "            INFORME DE ESCANEO NMAP            " >> "$TXT_FILE"
    echo "=============================================" >> "$TXT_FILE"
    echo "Tipo de escaneo    : $scan_type" >> "$TXT_FILE"
    echo "Objetivo           : $TARGET" >> "$TXT_FILE"
    echo "Fecha y hora       : $(date '+%a %d %b %Y %H:%M:%S %Z')" >> "$TXT_FILE"
    echo "Escaneando... Por favor, espere." >> "$TXT_FILE"
    geolocalizar_ip  # Llamada a la función de geolocalización
    echo "---------------------------------------------" >> "$TXT_FILE"
    echo "Escaneando... Por favor, espere."
    nmap $nmap_args $TARGET -oN - >> "$TXT_FILE"
    mostrar_progreso 10
    echo "[+] Escaneo $scan_type completado. Resultados guardados en $TARGET_DIR"
}

# Menú interactivo con diseño mejorado
while true; do
    clear
    echo "=============================================="
    echo "            HERRAMIENTA DE ESCANEO NMAP            "
    echo "=============================================="
    echo "Fecha: $(date '+%A, %d de %B de %Y %H:%M:%S')"
    echo "----------------------------------------------"
    echo "Objetivo actual: $TARGET"
    echo "Seleccione una opción de escaneo:"
    echo "1. Escaneo rápido de hosts activos (-sn)"
    echo "2. Escaneo de puertos comunes (-F)"
    echo "3. Escaneo completo de puertos (-p-) (Nota: Puede ser muy ruidoso)"
    echo "4. Detección de sistema operativo (-O)"
    echo "5. Detección de versiones de servicios (-sV)"
    echo "6. Análisis de vulnerabilidades (--script=vuln)"
    echo "7. Escaneo agresivo (-A)"
    echo "8. Escaneo UDP (-sU)"
    echo "9. Introducir una nueva IP o subred"
    echo "10. Salir"
    echo "----------------------------------------------"

    read -p "Ingrese su opción: " temp_option
    echo "Procesando la opción seleccionada..."

    case $temp_option in
        1) ejecutar_nmap "Hosts activos" "-sn" ;;
        2) ejecutar_nmap "Puertos comunes" "-F" ;;
        3) ejecutar_nmap "Puertos completos" "-p-" ;;
        4) ejecutar_nmap "Sistema operativo" "-O" ;;
        5) ejecutar_nmap "Versiones de servicios" "-sV" ;;
        6) ejecutar_nmap "Vulnerabilidades" "-sV --script=vuln" ;;
        7) ejecutar_nmap "Escaneo agresivo" "-A" ;;
        8) ejecutar_nmap "Escaneo UDP" "-sU" ;;
        9) read -p "Introduce la nueva IP o subred: " TARGET ;;
        10) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida, intenta de nuevo." ;;
    esac
done
