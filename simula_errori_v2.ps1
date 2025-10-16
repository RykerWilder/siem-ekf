#
# Generatore di log SSH per demo SIEM: più eventi casuali per file e rotazione.
# Per eseguire:
# powershell -ExecutionPolicy Bypass .\simula_errori_v2.ps1

# --- CONFIGURAZIONE ---
$LogDir = ".\logs"
$counter = 0
$MaxFiles = $null               # numero massimo file da creare, $null = infinito
$MinSleep = 1                   # sleep tra file in secondi
$MaxSleep = 3
$BurstProbability = 0.12
$PortScanBurstMin = 5
$PortScanBurstMax = 25
$HostnamePool = @("server1","gateway","bastion","edge01","ssh-host")

# --- CONTROLLO SU COME SCRIVERE I FILE ---
$UseSingleFile = $false         # $false = molti file (uno per "batch"), $true = un singolo file rotante/appending
$SingleFileName = "simulated-ssh.log"
$RotateByMaxLines = $true       # applicabile solo se $UseSingleFile = $true
$MaxLinesPerSingleFile = 10000  # rotazione quando il file raggiunge questo numero di linee
$RotateBySizeBytes = $false     # alternativa: ruota per dimensione (in bytes)
$MaxFileSizeBytes = 5MB         # valida solo se $RotateBySizeBytes = $true

# --- EVENTI PER FILE ---
$MinEventsPerFile = 5           # numero minimo di eventi scritti in ogni file (batch)
$MaxEventsPerFile = 40          # massimo

# --- LISTE DATI ---
$users = @("root","admin","test","user1","guest","svc_backup","deploy","oracle","www-data","backup")
$ips = @("192.168.1.100","10.0.0.10","172.16.0.2","192.168.1.55","10.1.1.8","203.0.113.45","198.51.100.23")
$ipv6s = @("2001:0db8:85a3::8a2e:0370:7334","fe80::1ff:fe23:4567:890a")
$ports = 1024..65535

# --- TEMPLATE DI LOG ---
$templates = @(
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Failed password for invalid user $u from ${ip} port ${port} ssh2" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Failed password for $u from ${ip} port ${port} ssh2" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Accepted password for $u from ${ip} port ${port} ssh2" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Connection closed by authenticating user $u ${ip} port ${port} [preauth]" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Disconnect from ${ip} port ${port}: Too many authentication failures" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: error: maximum authentication attempts exceeded for $u from ${ip} port ${port} ssh2" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Did not receive identification string from ${ip}" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: reverse mapping checking getaddrinfo for ${ip} failed - possible spoofing?" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: error: Could not load host key: /etc/ssh/ssh_host_rsa_key" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=${ip}  user=$u" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Invalid user $u from ${ip} port ${port}" },
    { param($t,$h,$proc,$u,$ip,$port) "$t $h sshd[$proc]: Failed publickey for $u from ${ip} port ${port} ssh2: RSA SHA256:abcdef..." }
)

$portScanTemplate = {
    param($t,$h,$proc,$u,$ip,$port)
    "$t $h sshd[$proc]: Connection attempt to port ${port} from ${ip} for user $u - no auth (possible port scan)"
}

# --- UTILI ---
function Ensure-LogDir { param($dir) if (-not (Test-Path -Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null } }
function Write-LogToFile {
    param($lines, $filename)
    # $lines = array di stringhe
    $dir = Split-Path -Parent $filename
    if (-not (Test-Path -Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $lines | Add-Content -Path $filename
    Write-Host "Wrote $($lines.Count) eventi in $filename" -ForegroundColor Green
}

function Get-SingleFilePath {
    param($baseDir, $baseName, $index)
    return Join-Path $baseDir ("{0}-{1:0000}.log" -f $baseName, $index)
}

# --- START ---
Ensure-LogDir -dir $LogDir
$singleFileIndex = 1
$currentSingleFile = Join-Path $LogDir $SingleFileName
$currentSingleFileLines = 0

while ($true) {
    if ($MaxFiles -ne $null -and $counter -ge $MaxFiles) {
        Write-Host "Generati $counter file. Termine." -ForegroundColor Yellow
        break
    }

    # Decidi quanti eventi scrivere in questo file
    $eventsCount = Get-Random -Minimum $MinEventsPerFile -Maximum $MaxEventsPerFile
    $batchLines = New-Object System.Collections.Generic.List[string]

    for ($e=0; $e -lt $eventsCount; $e++) {
        $hostname = Get-Random -InputObject $HostnamePool
        $user = Get-Random -InputObject $users
        $useIpv6 = (Get-Random -Minimum 0 -Maximum 10) -gt 7
        $ip = if ($useIpv6) { Get-Random -InputObject $ipv6s } else { Get-Random -InputObject $ips }
        $port = Get-Random -InputObject $ports
        $procId = Get-Random -Minimum 1000 -Maximum 99999
        $timestamp = Get-Date -Format "MMM dd HH:mm:ss"

        # Possibile burst interno (simula piccolo port-scan N righe consecutive nello stesso batch)
        if ((Get-Random) -lt $BurstProbability) {
            $burstCount = Get-Random -Minimum 3 -Maximum 8
            for ($b=0; $b -lt $burstCount; $b++) {
                $p = Get-Random -InputObject $ports
                $line = & $portScanTemplate $timestamp $hostname $procId $user $ip $p
                $batchLines.Add($line)
            }
            continue
        }

        # Scegli template normale
        $tpl = Get-Random -InputObject $templates
        $line = & $tpl $timestamp $hostname $procId $user $ip $port

        # Occasionalmente aggiungi righe correlate (es. PAM seguito da disconnect)
        if ((Get-Random -Minimum 0 -Maximum 10) -gt 8) {
            $line2 = "$timestamp $hostname sshd[$procId]: pam_unix(sshd:auth): authentication failure; user=$user rhost=${ip}"
            $batchLines.Add($line)
            $batchLines.Add($line2)
        } else {
            $batchLines.Add($line)
        }
    }

    # SCRITTURA: single file o file separato per batch
    if ($UseSingleFile) {
        # Rotazione per linee
        if ($RotateByMaxLines -and $currentSingleFileLines + $batchLines.Count -gt $MaxLinesPerSingleFile) {
            # ruota: salva con indice e ricomincia
            $rotatedName = Get-SingleFilePath -baseDir $LogDir -baseName ([IO.Path]::GetFileNameWithoutExtension($SingleFileName)) -index $singleFileIndex
            Move-Item -Path $currentSingleFile -Destination $rotatedName -ErrorAction SilentlyContinue
            Write-Host "Rotated single file -> $rotatedName" -ForegroundColor Yellow
            $singleFileIndex++
            $currentSingleFileLines = 0
        } elseif ($RotateBySizeBytes -and (Test-Path $currentSingleFile) -and ((Get-Item $currentSingleFile).Length -gt $MaxFileSizeBytes)) {
            $rotatedName = Get-SingleFilePath -baseDir $LogDir -baseName ([IO.Path]::GetFileNameWithoutExtension($SingleFileName)) -index $singleFileIndex
            Move-Item -Path $currentSingleFile -Destination $rotatedName -ErrorAction SilentlyContinue
            Write-Host "Rotated single file by size -> $rotatedName" -ForegroundColor Yellow
            $singleFileIndex++
            $currentSingleFileLines = 0
        }

        # Scrivi (append)
        Write-LogToFile -lines $batchLines -filename $currentSingleFile
        $currentSingleFileLines += $batchLines.Count
    } else {
        # file separato: uno per batch (più eventi dentro)
        $counter++
        $fileName = Join-Path $LogDir ("attack-{0:000000}.log" -f $counter)
        Write-LogToFile -lines $batchLines -filename $fileName
    }

    # Sleep casuale tra i batch/file
    $sleep = Get-Random -Minimum $MinSleep -Maximum $MaxSleep
    Start-Sleep -Seconds $sleep
}
