#
# Simple script to pull down the Traefik Binary for deployment. 
# Overwride URL to upgrade versions to new Binary
# 

param([string]$url="https://github.com/jjcollinge/traefik-on-service-fabric/releases/download/v0.01/traefik.exe")

Write-Host "Downloading Traefik Binary from $url" -foregroundcolor Green
Write-Host "to use a specific binary use -url arg" -foregroundcolor Green

$outfile = $PSScriptRoot+"/../ApplicationPackageRoot/TraefikPkg/Code/traefik.exe"

# Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing

Write-Host "Download complete" -foregroundcolor Green

Write-Host "Traefik version downloaded:" -foregroundcolor Green

& $outfile version

