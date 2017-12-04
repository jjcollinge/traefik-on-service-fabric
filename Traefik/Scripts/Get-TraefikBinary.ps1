#
# Simple script to pull down the Traefik Binary for deployment. 
# Overwride URL to upgrade versions to new Binary
# 

param(
	[string]$url="https://github.com/containous/traefik/releases/download/v1.5.0-rc1/traefik_windows-amd64.exe",
	[string]$urlWatchdog="https://github.com/lawrencegripper/traefik-appinsights-watchdog/releases/download/v0.0.3/windows_traefik-appinsights-watchdog.exe"
)

Write-Host "Downloading Traefik Binary from $url" -foregroundcolor Green
Write-Host "to use a specific binary use -url arg" -foregroundcolor Green

$outfile = $PSScriptRoot+"/../ApplicationPackageRoot/TraefikPkg/Code/traefik.exe"
$outfileWatchdog = $PSScriptRoot+"/../ApplicationPackageRoot/Watchdog/Code/traefik-appinsights-watchdog.exe"

Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing
Invoke-WebRequest -Uri $urlWatchdog -OutFile $outfileWatchdog -UseBasicParsing

Write-Host "Download complete" -foregroundcolor Green

Write-Host "Traefik version downloaded:" -foregroundcolor Green

& $outfile version

