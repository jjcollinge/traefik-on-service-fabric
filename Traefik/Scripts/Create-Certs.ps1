<#
.SYNOPSIS 
Creates PEM certificates and key files required by Traefik from an existing .Pfx

.DESCRIPTION
Takes an existing .Pfx certificate and extracts the PEM client certificate and key

.PARAMETER PfxCertFilePath
Path to existing .Pfx certificate file

.PARAMETER PfxPassphraseFilePath
Path to permissioned ANSI passphrase file

.PARAMETER CASubject
CA Subject string i.e. "/C=GB/ST=England/L=London/O=Joni/CN=www.example.com"

.EXAMPLE
PS> Create-Certs.ps1 -PfxCertFilePath mycert.pfx -PfxPassphraseFilePath mypass.txt -CASubject  "/C=GB/ST=England/L=London/O=Joni/CN=www.example.com"

.NOTES
This script is meant as a tool for testing a Traefik Service Fabric deployment.
For a production cluster - you will likely generate a READ-ONLY client certificate,
upload it to your cluster, extract the certificate and keys from it and then pass those
to Traefik. You will also require a more secure strategy to hanlding root CA signers.

This script requires execution policy to be set to unrestricted:
`Set-ExectuionPolicy -ExecutionPolicy unrestricted -Scope CurrentUser`

Author: @dotjson
#>

param (
    [Parameter(Mandatory=$true)]
    [string]
    $PfxCertFilePath,
    [Parameter(Mandatory=$true)]
    [string]
    $PfxPassphraseFilePath,
    [Parameter(Mandatory=$true)]
    [string]
    $CASubject,
    [Parameter(Mandatory=$false)]
    [string]
    $OutputCertDir="certs",
    [Parameter(Mandatory=$false)]
    [string]
    $CACertOutputName="cacert",
    [Parameter(Mandatory=$false)]
    [string]
    $ClientCertOutputName="clientcert",
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

# Existing .PFX passphrase file
if ( -Not(Test-Path -Path $PfxPassphraseFilePath))
{
    Write-Error "PfxCertPasswordFilePath " + $PfxCertPasswordFilePath + " does not exist"
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

# A bug/feature in OpenSSL requires unique passphrase
# files for passin and passout n if the same
# See: https://rt.openssl.org/Ticket/Display.html?id=3168&user=guest&pass=guest

# Create copy of existing passphrase file to use to secure PEM files
$PemPassphraseFilePath="pempass.txt"
if (Test-Path -Path $PemPassphraseFilePath)
{
    Remove-Item -Path $PemPassphraseFilePath
}
New-Item -Path $PemPassphraseFilePath -Type File > $null
.\Copy-Acl.ps1 -FromPath $PfxPassphraseFilePath -Destination $PemPassphraseFilePath
Get-Content $PfxPassphraseFilePath | Out-File $PemPassphraseFilePath

# Extract client private key
# Creates a passphrase encrypted .key file
$EncryptedClientKeyOutputPath = BuildOutputPath -fileName $ClientCertOutputName -fileExtension "_encrypted.key"
openssl pkcs12 -in $PfxCertFilePath -nocerts -out $EncryptedClientKeyOutputPath -passin file:$PfxPassphraseFilePath -passout file:$PemPassphraseFilePath > $null 2>&1
# Extract client certificate
# Creates a .crt certificate file
$ClientCertOutputPath = BuildOutputPath -fileName $ClientCertOutputName -fileExtension ".crt"
openssl pkcs12 -in $PfxCertFilePath -clcerts -nokeys -out $ClientCertOutputPath -passin file:$PfxPassphraseFilePath > $null 2>&1

# CAUTION: Unencrypts private key file (store file with care)
# Creates an unencrypted .key file
$ClientKeyOutputPath = BuildOutputPath -fileName $ClientCertOutputName -fileExtension ".key"
openssl rsa -in $EncryptedClientKeyOutputPath -out $ClientKeyOutputPath -passin file:$PemPassphraseFilePath > $null 2>&1

# Generates a Root CA certificate using our private key file 
$CACertOutputPath = BuildOutputPath -fileName $CACertOutputName -fileExtension ".cer"
openssl req -x509 -new -nodes -key $ClientKeyOutputPath -days $Duration -out $CACertOutputPath -subj $CASubject > $null 2>&1

# Clean-up temporary files
Remove-Item $PemPassphraseFilePath

Write-Host "All generated files have been placed within the directory: $OutputCertDir"
Write-Host "To use these files with traefik, move them to ..\ApplicationPackageRoot\TraefikPkg\Code\certs"
Write-Host "Ensure your traefik.toml has the correct paths for the parameters"
Write-Host " - clientcertfilepath"
Write-Host " - clientcertkeyfilepath"
Write-Host " - cacertfilepath"