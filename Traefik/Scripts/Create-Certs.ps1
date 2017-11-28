<#
.SYNOPSIS 
Creates PEM certificates and key files required by Traefik from an existing .Pfx

.DESCRIPTION
Takes an existing .Pfx certificate and extracts the PEM client certificate and key

.PARAMETER PfxCertFilePath
Path to existing .Pfx certificate file

.PARAMETER PfxPassphraseFilePath
Path to permissioned ANSI passphrase file

.EXAMPLE
PS> Create-Certs.ps1 -PfxCertFilePath mycert.pfx -PfxPassphraseFilePath mypass.txt

.NOTES
This script is meant as a tool for testing a Traefik Service Fabric deployment.
For a production cluster - you will likely generate a READ-ONLY client certificate,
upload it to your cluster, extract the certificate and keys from it and then pass those
to Traefik.

This script requires execution policy to be set to unrestricted:
`Set-ExectuionPolicy -ExecutionPolicy unrestricted -Scope CurrentUser`

Author: @dotjson
#>

param (
    [Parameter(Mandatory=$true)]
    [string]
    $PfxCertFilePath,
    [Parameter(Mandatory=$false)]
    [string]
    $PfxPassphraseFilePath,
    [Parameter(Mandatory=$false)]
    [string]
    $OutputCertDir="certs",
    [Parameter(Mandatory=$false)]
    [string]
    $ClientCertOutputName="client",
    [Parameter(Mandatory=$false)]
    [int16]
    $Duration=365
 )

############################
# Functions
############################

function BuildOutputPath ([String]$fileName, [String]$fileExtension) {
    $OutputPath = Join-Path -Path $OutputCertDir -ChildPath ($fileName + $fileExtension)
    return $OutputPath
}

############################
# Test Prerequisites
############################

# OpenSSL
if ( -Not(Get-Command "openssl.exe" -ErrorAction SilentlyContinue))
{ 
    Write-Error "openssl must be installed to run this script"
    exit
}

# Existing .PFX file
if ( -Not(Test-Path -Path $PfxCertFilePath -ErrorAction SilentlyContinue))
{
    Write-Error "PfxCertFilePath " + $PfxCertFilePath + " does not exist"
    exit
}

# Output directory
if ( -Not(Test-Path -Path $OutputCertDir))
{
    New-Item -ItemType directory -Path $OutputCertDir > $null
}

############################
# Main
############################

if ($PfxPassphraseFilePath) 
{
    # Passphrase file provided but empty
    $UsePassphraseFile = (Get-Item $PfxPassphraseFilePath).length -gt 0kb
}

$ClientKeyOutputPath = BuildOutputPath -fileName $ClientCertOutputName -fileExtension ".key"
$ClientCertOutputPath = BuildOutputPath -fileName $ClientCertOutputName -fileExtension ".crt"
if ($UsePassphraseFile)
{
    # Extract private key
    openssl pkcs12 -in $PfxCertFilePath -nocerts -nodes -out $ClientKeyOutputPath -passin file:$PfxPassphraseFilePath > $null 2>&1
    # Extract certificate
    openssl pkcs12 -in $PfxCertFilePath -clcerts -nokeys -nodes -out $ClientCertOutputPath -passin file:$PfxPassphraseFilePath > $null 2>&1
}
else
{
    # No passphrase

    # Extract private key
    openssl pkcs12 -in $PfxCertFilePath -nocerts -nodes -out $ClientKeyOutputPath -passin pass:'' > $null 2>&1
    # Extract certificate
    openssl pkcs12 -in $PfxCertFilePath -clcerts -nokeys -out $ClientCertOutputPath -passin pass:'' > $null 2>&1
}

Write-Host "All generated files have been placed within the directory: $OutputCertDir"
Write-Host "To use these files with Traefik, move them to ..\ApplicationPackageRoot\TraefikPkg\Code\certs"
Write-Host "Ensure your traefik.toml has the correct serviceFabric.tls configuration set."