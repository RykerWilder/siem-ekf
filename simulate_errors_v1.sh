#!/bin/bash

# Simulate SSH errors by writing a new log file each time
# To run: ./simulate_errors_v1.sh

logDir="./logs"
counter=0

users=("root" "admin" "test" "user1" "guest")
ips=("192.168.1.100" "10.0.0.10" "172.16.0.2" "192.168.1.55" "10.1.1.8")

# Create port array
ports=()
for port in $(seq 1024 65535); do
    ports+=($port)
done

# Create logs directory if it does not exist
if [ ! -d "$logDir" ]; then
    mkdir -p "$logDir"
fi

# Function to get random element from array
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
    echo "Log generated: $line in $logFile"

    # Sleep between 1 and 3 seconds
    sleepTime=$((1 + RANDOM % 3))
    sleep $sleepTime
done