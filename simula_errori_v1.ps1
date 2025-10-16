# Simula errori SSH scrivendo ogni volta un nuovo file di log
# Per eseguire:
# powershell -ExecutionPolicy Bypass .\simula_errori_v1.ps1

$logDir = ".\logs"
$counter = 0

$users = @("root", "admin", "test", "user1", "guest")
$ips = @("192.168.1.100", "10.0.0.10", "172.16.0.2", "192.168.1.55", "10.1.1.8")
$ports = 1024..65535

while ($true) {
    $user = Get-Random -InputObject $users
    $ip = Get-Random -InputObject $ips
    $port = Get-Random -InputObject $ports
    $procId = Get-Random -Minimum 1000 -Maximum 9999
    $timestamp = Get-Date -Format "MMM dd HH:mm:ss"
    $line = "$timestamp localhost sshd[$procId]: Failed password for invalid user $user from $ip port $port ssh2"

    $counter++
    $logFile = Join-Path $logDir ("attack-{0:000}.log" -f $counter)
    Add-Content -Path $logFile -Value $line
    Write-Host "Log generato: $line in $logFile"
    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 3)
}