# .\DeleteInstances.ps1 -pemFile .\mknor-vault-Test.pem `
#   -sfClusterUrl https://mk-local.westeurope.cloudapp.azure.com:19080 `
#   -sfAppServiceType TestSiteType
Param(
    [Parameter(Mandatory = $true)][string]$sfClusterUrl,
    [Parameter(Mandatory = $true)][string]$pemFile,
    [Parameter(Mandatory = $true)][string]$sfAppServiceType
)

# Connect to the cluster
Write-Host "Connecting to cluster $($sfClusterUrl)"
sfctl cluster select --endpoint $sfClusterUrl --pem $pemFile --no-verify

$filter = "'" + $sfAppServiceType + "'"

$apps = sfctl application list --query items[?typeName==$filter].name
$appsArray = (ConvertFrom-Json ([string]::Concat($apps)))

foreach ($a in $appsArray) {
    $appId = $a -replace "fabric:/",""
    sfctl application delete --application-id $appId
}

return;

function replaceText($file, $find, $replace) {
    (Get-Content $file).replace($find, $replace) | Set-Content $file
}