param (
    [Parameter(Mandatory=$true)]
    [string]
    $PfxCertFilePath,
    [Parameter(Mandatory=$true)]
    [securestring]
    $PfxCertPassword,
    [Parameter(Mandatory=$false)]
    [string]
    $OutputCertDir="certs",
    [Parameter(Mandatory=$false)]
    [string]
    $OutputCACertName="cacert",
    [Parameter(Mandatory=$false)]
    [string]
    $OutputClientCertName="clientcert",
    [Parameter(Mandatory=$false)]
    [int16]
    $Duration=365
 )

if ( -Not(Get-Command "openssl.exe" -ErrorAction SilentlyContinue))
{ 
    Write-Error "openssl must be installed to run this script"
    exit
}

if ( -Not(Test-Path -Path $PfxCertFilePath -ErrorAction SilentlyContinue))
{
    Write-Error "PfxCertFilePath " + $PfxCertFilePath + " does not exist"
    exit
}

if ( -Not(Test-Path -Path $OutputCertDir)
{
    New-Item -ItemType directory -Path $OutputCertDir
} 

$OutputEncryptedClientKeyPath = $OutputCertDir + "\" + $OutputClientCertName + "-encrypted.key"
$OutputClientKeyPath = $OutputCertDir + "\" + $OutputClientCertName + ".key"
# Extract private key
openssl pkcs12 -in $PfxCertFilePath -nocerts -out $OutputEncryptedClientKeyPath
# Unencrypt private key
openssl rsa -in $OutputEncryptedClientKeyPath -out $OutputClientKeyPath
# Extract certificate
$OutputClientCertPath = $OutputCertDir + "\" + $OutputClientCertName + ".crt"
openssl pkcs12 -in $PfxCertFilePath -clcerts -nokeys -out $OutputClientCertPath
# Generate CA certificate
$OutputCACertPath = $OutputCertDir + "\" + $OutputCACertName + "cer"
openssl req -x509 -new -nodes -key $OutputClientKeyPath -days $Duration -out $OutputCACertPath