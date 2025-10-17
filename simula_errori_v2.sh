#!/bin/bash

#
# Generatore di log SSH per demo SIEM: più eventi casuali per file e rotazione.
# Per eseguire: ./simula_errori_v2.sh
#

# --- CONFIGURAZIONE ---
LogDir="./logs"
counter=0
MaxFiles=""               # numero massimo file da creare, "" = infinito
MinSleep=1                # sleep tra file in secondi
MaxSleep=3
BurstProbability=0.12
PortScanBurstMin=5
PortScanBurstMax=25
HostnamePool=("server1" "gateway" "bastion" "edge01" "ssh-host")

# --- CONTROLLO SU COME SCRIVERE I FILE ---
UseSingleFile=false       # false = molti file (uno per "batch"), true = un singolo file rotante/appending
SingleFileName="simulated-ssh.log"
RotateByMaxLines=true     # applicabile solo se $UseSingleFile = true
MaxLinesPerSingleFile=10000  # rotazione quando il file raggiunge questo numero di linee
RotateBySizeBytes=false   # alternativa: ruota per dimensione (in bytes)
MaxFileSizeBytes=5242880  # 5MB in bytes (valida solo se $RotateBySizeBytes = true)

# --- EVENTI PER FILE ---
MinEventsPerFile=5        # numero minimo di eventi scritti in ogni file (batch)
MaxEventsPerFile=40       # massimo

# --- LISTE DATI ---
users=("root" "admin" "test" "user1" "guest" "svc_backup" "deploy" "oracle" "www-data" "backup")
ips=("192.168.1.100" "10.0.0.10" "172.16.0.2" "192.168.1.55" "10.1.1.8" "203.0.113.45" "198.51.100.23")
ipv6s=("2001:0db8:85a3::8a2e:0370:7334" "fe80::1ff:fe23:4567:890a")

# Genera array di porte
ports=()
for port in $(seq 1024 65535); do
    ports+=($port)
done

# --- FUNZIONI UTILI ---
ensure_logdir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

write_log_to_file() {
    local lines=("${!1}")  # Passa array by name
    local filename="$2"
    local dir=$(dirname "$filename")
    
    ensure_logdir "$dir"
    printf "%s\n" "${lines[@]}" >> "$filename"
    echo -e "\033[32mWrote ${#lines[@]} eventi in $filename\033[0m"
}

get_single_file_path() {
    local baseDir="$1"
    local baseName="$2"
    local index="$3"
    printf "%s/%s-%04d.log" "$baseDir" "$baseName" "$index"
}

random_element() {
    local arr=("${!1}")
    local size=${#arr[@]}
    local index=$((RANDOM % size))
    echo "${arr[$index]}"
}

random_range() {
    local min=$1
    local max=$2
    echo $((min + RANDOM % (max - min + 1)))
}

random_float() {
    echo "scale=2; $RANDOM/32767" | bc -l
}

# --- TEMPLATE DI LOG come funzioni ---
template1() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Failed password for invalid user $u from ${ip} port ${port} ssh2"
}

template2() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Failed password for $u from ${ip} port ${port} ssh2"
}

template3() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Accepted password for $u from ${ip} port ${port} ssh2"
}

template4() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Connection closed by authenticating user $u ${ip} port ${port} [preauth]"
}

template5() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Disconnect from ${ip} port ${port}: Too many authentication failures"
}

template6() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: error: maximum authentication attempts exceeded for $u from ${ip} port ${port} ssh2"
}

template7() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Did not receive identification string from ${ip}"
}

template8() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: reverse mapping checking getaddrinfo for ${ip} failed - possible spoofing?"
}

template9() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: error: Could not load host key: /etc/ssh/ssh_host_rsa_key"
}

template10() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=${ip}  user=$u"
}

template11() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Invalid user $u from ${ip} port ${port}"
}

template12() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Failed publickey for $u from ${ip} port ${port} ssh2: RSA SHA256:abcdef..."
}

portScanTemplate() {
    local t=$1 h=$2 proc=$3 u=$4 ip=$5 port=$6
    echo "$t $h sshd[$proc]: Connection attempt to port ${port} from ${ip} for user $u - no auth (possible port scan)"
}

# Array di funzioni template
templates=(
    template1 template2 template3 template4 template5 
    template6 template7 template8 template9 template10 
    template11 template12
)

# --- INIZIALIZZAZIONE ---
ensure_logdir "$LogDir"
singleFileIndex=1
currentSingleFile="$LogDir/$SingleFileName"
currentSingleFileLines=0

# Verifica se bc è installato per random_float
if ! command -v bc &> /dev/null; then
    echo "Errore: 'bc' non è installato. Installa con: sudo apt-get install bc"
    exit 1
fi

# --- LOOP PRINCIPALE ---
while true; do
    if [ -n "$MaxFiles" ] && [ "$counter" -ge "$MaxFiles" ]; then
        echo -e "\033[33mGenerati $counter file. Termine.\033[0m"
        break
    fi

    # Decidi quanti eventi scrivere in questo file
    eventsCount=$(random_range $MinEventsPerFile $MaxEventsPerFile)
    batchLines=()

    for ((e=0; e<eventsCount; e++)); do
        hostname=$(random_element "HostnamePool[@]")
        user=$(random_element "users[@]")
        
        # 30% probabilità di usare IPv6
        if [ $((RANDOM % 10)) -gt 6 ]; then
            ip=$(random_element "ipv6s[@]")
        else
            ip=$(random_element "ips[@]")
        fi
        
        port=$(random_element "ports[@]")
        procId=$(random_range 1000 99999)
        timestamp=$(date +"%b %d %H:%M:%S")

        # Possibile burst interno (simula piccolo port-scan)
        if (( $(echo "$(random_float) < $BurstProbability" | bc -l) )); then
            burstCount=$(random_range 3 7)
            for ((b=0; b<burstCount; b++)); do
                p=$(random_element "ports[@]")
                line=$(portScanTemplate "$timestamp" "$hostname" "$procId" "$user" "$ip" "$p")
                batchLines+=("$line")
            done
            continue
        fi

        # Scegli template normale
        template=$(random_element "templates[@]")
        line=$($template "$timestamp" "$hostname" "$procId" "$user" "$ip" "$port")

        # Occasionalmente aggiungi righe correlate (20% probabilità)
        if [ $((RANDOM % 10)) -gt 7 ]; then
            line2="$timestamp $hostname sshd[$procId]: pam_unix(sshd:auth): authentication failure; user=$user rhost=${ip}"
            batchLines+=("$line")
            batchLines+=("$line2")
        else
            batchLines+=("$line")
        fi
    done

    # SCRITTURA: single file o file separato per batch
    if [ "$UseSingleFile" = true ]; then
        # Rotazione per linee
        if [ "$RotateByMaxLines" = true ] && [ $((currentSingleFileLines + ${#batchLines[@]})) -gt $MaxLinesPerSingleFile ]; then
            rotatedName=$(get_single_file_path "$LogDir" "${SingleFileName%.*}" "$singleFileIndex")
            if [ -f "$currentSingleFile" ]; then
                mv "$currentSingleFile" "$rotatedName"
            fi
            echo -e "\033[33mRotated single file -> $rotatedName\033[0m"
            ((singleFileIndex++))
            currentSingleFileLines=0
        elif [ "$RotateBySizeBytes" = true ] && [ -f "$currentSingleFile" ] && [ $(stat -f%z "$currentSingleFile" 2>/dev/null || stat -c%s "$currentSingleFile") -gt $MaxFileSizeBytes ]; then
            rotatedName=$(get_single_file_path "$LogDir" "${SingleFileName%.*}" "$singleFileIndex")
            if [ -f "$currentSingleFile" ]; then
                mv "$currentSingleFile" "$rotatedName"
            fi
            echo -e "\033[33mRotated single file by size -> $rotatedName\033[0m"
            ((singleFileIndex++))
            currentSingleFileLines=0
        fi

        # Scrivi (append)
        write_log_to_file "batchLines[@]" "$currentSingleFile"
        ((currentSingleFileLines += ${#batchLines[@]}))
    else
        # file separato: uno per batch (più eventi dentro)
        ((counter++))
        fileName="$LogDir/attack-$(printf "%06d" $counter).log"
        write_log_to_file "batchLines[@]" "$fileName"
    fi

    # Sleep casuale tra i batch/file
    sleepTime=$(random_range $MinSleep $MaxSleep)
    sleep $sleepTime
done