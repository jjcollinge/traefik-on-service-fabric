# .\CreateNewInstances.ps1 -pemFile .\mknor-vault-Test.pem `
#   -sfClusterUrl https://mk-local.westeurope.cloudapp.azure.com:19080 `
#    -sfAppServiceType TestSiteType `
#    -sfAppUrl fabric:/testweb `
#    -sfAppServiceName Web `
#    -instanceCount 2
Param(
    [Parameter(Mandatory = $true)][string]$sfClusterUrl,
    [Parameter(Mandatory = $true)][string]$pemFile,
    [Parameter(Mandatory = $true)][string]$sfAppUrl,
    [Parameter(Mandatory = $true)][string]$sfAppServiceName,
    [Parameter(Mandatory = $true)][string]$sfAppServiceType,
    [string ]$sfAppVersion = "1.0.0",
    [string]$pathPrefix = "/web",
    [int]$instanceCount = 1,
    [int]$instanceStartNumber = 0
)

# Connect to the cluster
Write-Host "Connecting to cluster $($sfClusterUrl)"
sfctl cluster select --endpoint $sfClusterUrl --pem $pemFile --no-verify

$top = $instanceStartNumber + $instanceCount;

for ($i = $instanceStartNumber; $i -lt $top; $i++) {
    $instanceUrl = "$($sfAppUrl)$($i)"

    Write-Host "Deploying application $($instanceUrl) - type $sfAppServiceType ($sfAppVersion)"

    $path = $pathPrefix + "$($i)"

    sfctl application create --app-name $instanceUrl --app-type $sfAppServiceType --app-version $sfAppVersion

    $json = '{\"Kind\": \"String\",\"Data\": \"PathPrefixStrip: ' + $path + '\"}'

    $sfAppId = "$($sfAppUrl)$($i)/$($sfAppServiceName)" -replace "fabric:/", ""

    Write-Host "Setting property ""traefik.frontend.rule.rule$($i)"" on $($sfAppId)"

    sfctl property put --name-id $sfAppId `
        --property-name "traefik.frontend.rule.rule$($i)" `
        --value $json

    
    $json = '{\"Kind\": \"String\",\"Data\": \"true\"}'

    $sfAppId = "$($sfAppUrl)$($i)/$($sfAppServiceName)" -replace "fabric:/", ""

    Write-Host "Setting property ""traefik.expose"" on $($sfAppId)"

    sfctl property put --name-id $sfAppId `
        --property-name "traefik.expose" `
        --value $json
}

return;

function replaceText($file, $find, $replace) {
    (Get-Content $file).replace($find, $replace) | Set-Content $file
}