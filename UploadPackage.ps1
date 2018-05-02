# .\UploadPackage.ps1 -pemFile .\mknor-vault-Test.pem `
#   -sfClusterUrl https://mk-local.westeurope.cloudapp.azure.com:19080 `
#    -applicationPackageRoot .\testsite\TestSite\pkg\Debug
Param(
    [Parameter(Mandatory = $true)][string]$sfClusterUrl,
    [Parameter(Mandatory = $true)][string]$pemFile,
    [Parameter(Mandatory = $true)][string]$applicationPackageRoot,
)

# Connect to the cluster
Write-Host "Connecting to cluster $($sfClusterUrl)"
sfctl cluster select --endpoint $sfClusterUrl --pem $pemFile --no-verify

Write-Host "Upload application package from $($applicationPackageRoot)"
sfctl application upload --path $applicationPackageRoot --show-progress

# Provision the application package
# The actual package name is the last part of the $applicationPackageRoot path
$packageName = (Convert-Path $applicationPackageRoot) | Split-Path -Leaf

Write-Host "Provisioning package name $($packageName)"
sfctl application provision --application-type-build-path $packageName
