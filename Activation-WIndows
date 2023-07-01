param (
    [Parameter(Mandatory=$true)]
    [String]$LicenseKey,
    [Switch]$Debug,
    [Switch]$Help,
    [Switch]$EnableRemoteDesktop
)

# Funktion zum Anzeigen von Debug-Nachrichten
function Debug-Message {
    param (
        [String]$Message
    )
    if ($Debug) {
        Write-Host "[DEBUG] $Message"
    }
}

if ($Help) {
    Write-Host "Dieses Skript aktiviert Windows Server 2022 und ermöglicht Remote Desktop."
    Write-Host "Verwendung: .\aktiviere-rdp.ps1 -LicenseKey <LIZENZSCHLÜSSEL> [-Debug] [-Help] [-EnableRemoteDesktop]"
    Write-Host "-LicenseKey: Erforderlich. Der gültige Lizenzschlüssel für Windows Server 2022."
    Write-Host "-Debug: Optional. Aktiviert den Debug-Modus, um Debug-Nachrichten anzuzeigen."
    Write-Host "-Help: Optional. Zeigt diese Hilfenachricht an."
    Write-Host "-EnableRemoteDesktop: Optional. Aktiviert die Remote-Desktop-Funktion."
    Exit
}

try {
    # Produktaktivierung mit DISM
    $activationResult = DISM /Online /Set-Edition:ServerStandard /ProductKey:$LicenseKey /AcceptEula
    if ($activationResult.ExitCode -eq 0) {
        Write-Host "Produkt erfolgreich aktiviert."
    } else {
        Write-Host "Fehler bei der Produktaktivierung."
        Debug-Message -Message "DISM ExitCode: $($activationResult.ExitCode)"
    }

    if ($EnableRemoteDesktop) {
        # Remote Desktop aktivieren
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

        Write-Host "Remote Desktop wurde aktiviert."
    }

} catch {
    Write-Host "Fehler bei der Ausführung des Skripts:"
    Debug-Message -Message $_.Exception.Message
    Debug-Message -Message $_.ScriptStackTrace
}
