# Skript zur Einrichtung eines Active Directory-Domänendiensts

# Überprüfe, ob PowerShell als Administrator ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript muss als Administrator ausgeführt werden. Bitte öffne PowerShell als Administrator und versuche es erneut."
    Exit
}

# Überprüfe, ob die erforderlichen Features bereits installiert sind
$requiredFeatures = "AD-Domain-Services", "DNS", "RSAT-DNS-Server"
$missingFeatures = $requiredFeatures | Where-Object {-not (Get-WindowsFeature -Name $_ -ErrorAction SilentlyContinue).Installed}

if ($missingFeatures) {
    Write-Host "Es fehlen die folgenden Features: $($missingFeatures -join ', '). Führe 'Install-WindowsFeature' aus, um sie zu installieren."
    Exit
}

# Installiere die erforderlichen Features für den Domänendienst
Install-WindowsFeature -Name $requiredFeatures -IncludeManagementTools -ErrorAction Stop

# Konfiguriere die DNS-Rolle und -Funktionen
$dnsFeature = Get-WindowsFeature -Name DNS

if (-not $dnsFeature.Installed) {
    Write-Host "Die DNS-Rolle und die dazugehörigen Funktionen wurden nicht ordnungsgemäß installiert. Bitte überprüfe die Installation und versuche es erneut."
    Exit
}

# Konfiguriere den Domänencontroller
$domainName = "deine.domäne.com"
$domainNetBIOSName = "DEINE"
$domainAdminPassword = "Passwort123" # Ersetze dies durch dein eigenes Passwort

$securePassword = ConvertTo-SecureString -String $domainAdminPassword -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "DEINE\Administrator", $securePassword

$forestParams = @{
    DomainName = $domainName
    DomainNetbiosName = $domainNetBIOSName
    SafeModeAdministratorPassword = $credential.Password
    InstallDns = $true
    Force = $true
    Confirm = $false
    ErrorAction = Stop
}

try {
    Install-ADDSForest @forestParams
} catch {
    Write-Host "Fehler beim Konfigurieren des Domänencontrollers: $_"
    Exit
}

# Konfiguriere den DNS-Server
$dnsServerIPAddress = "192.168.0.1" # Ersetze dies durch deine gewünschte IP-Adresse
$dnsForwarders = "8.8.8.8", "8.8.4.4" # Ersetze dies durch deine bevorzugten DNS-Server

try {
    $zoneParams = @{
        Name = "$domainNetBIOSName.local"
        ReplicationScope = "Domain"
    }
    Set-DnsServerPrimaryZone @zoneParams

    Set-DnsServerForwarder -IPAddress $dnsForwarders
    Set-DnsServerRootHint -IPAddress $dnsForwarders
} catch {
    Write-Host "Fehler beim Konfigurieren des DNS-Servers: $_"
    Exit
}

# Starte den Domänendienst neu, um die Änderungen zu übernehmen
Write-Host "Der Domänendienst wurde erfolgreich konfiguriert. Der Computer wird jetzt neu gestartet."
Restart-Computer -Force
