#
# Simple script to pull down the Traefik Binary for deployment. 
# Overwride URL to upgrade versions to new Binary
# 

param(
    [string]$version,
    [string]$urlWatchdog = "https://github.com/lawrencegripper/traefik-appinsights-watchdog/releases/download/v0.0.3/windows_traefik-appinsights-watchdog.exe"
)

while (!($version)) {
    Write-Host "Review current Traefik releases:" -foregroundcolor Green
    Write-Host "https://github.com/containous/traefik/releases"
    Write-Host "Please provide the release tag (e.g. 'v1.6.0-rc6' or 'v1.5.4') of the Traefik release you wish to download: " -foregroundcolor Green -NoNewline
    $version = Read-Host 
}

#Github and other sites now require tls1.2 without this line the script will fail with an SSL error. 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

$traefikBaseUrl = "https://github.com/containous/traefik/releases/download/"
$url = $traefikBaseUrl + $version + "/traefik_windows-amd64.exe"

Write-Host "Downloading Traefik Binary from: " -foregroundcolor Green
Write-Host $url
Write-Host "Downloading Traefik Watchdog Binary from:" -foregroundcolor Green
Write-Host $urlWatchdog

$traefikPath = "/../ApplicationPackageRoot/TraefikPkg/Code/traefik.exe"
$treafikWatchdogPath = "/../ApplicationPackageRoot/Watchdog/Code/traefik-appinsights-watchdog.exe"
$outfile = Join-Path $PSScriptRoot $traefikPath
$outfileWatchdog = Join-Path $PSScriptRoot $treafikWatchdogPath

Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing
Invoke-WebRequest -Uri $urlWatchdog -OutFile $outfileWatchdog -UseBasicParsing

Write-Host "Download complete, files:" -foregroundcolor Green
Write-Host $outfile
Write-Host $outfileWatchdog

Write-Host "Traefik version downloaded:" -foregroundcolor Green

& $outfile version

