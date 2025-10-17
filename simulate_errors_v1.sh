#!/bin/bash

# Simula errori SSH scrivendo ogni volta un nuovo file di log
# Per eseguire: ./simula_errori_v1.sh

logDir="./logs"
counter=0

users=("root" "admin" "test" "user1" "guest")
ips=("192.168.1.100" "10.0.0.10" "172.16.0.2" "192.168.1.55" "10.1.1.8")

# Crea array di porte
ports=()
for port in $(seq 1024 65535); do
    ports+=($port)
done

# Crea directory logs se non esiste
if [ ! -d "$logDir" ]; then
    mkdir -p "$logDir"
fi

# Funzione per ottenere elemento random da array
random_element() {
    local arr=("${!1}")
    local size=${#arr[@]}
    local index=$((RANDOM % size))
    echo "${arr[$index]}"
}

while true; do
    user=$(random_element "users[@]")
    ip=$(random_element "ips[@]")
    port=$(random_element "ports[@]")
    procId=$((1000 + RANDOM % 9000))
    timestamp=$(date +"%b %d %H:%M:%S")
    line="$timestamp localhost sshd[$procId]: Failed password for invalid user $user from $ip port $port ssh2"

    ((counter++))
    logFile="$logDir/attack-$(printf "%03d" $counter).log"
    echo "$line" > "$logFile"
    echo "Log generato: $line in $logFile"
    
    # Sleep tra 1 e 3 secondi
    sleepTime=$((1 + RANDOM % 3))
    sleep $sleepTime
done