param (
    [bool]
    $removeTraffic = $False
 )


# Application package
$app1Package = 'apps\app1\v1.0.0'
$app1AppType = 'NodeAppType'
$app1ServiceName = 'WebService'
$app1ServiceType = 'WebServicePkg'

# Application2 package
$app2Package = 'apps\app1\v2.0.0'
$app2AppType = 'NodeAppType'
$app2ServiceName = 'WebService'
$app2ServiceType = 'WebServicePkg'

# Traefik package
$traefikPackage = 'traefik'
$traefikAppType = 'TraefikType'
$traefikServiceType = 'TraefikType'
$traefikFabricName = 'fabric:/Traefik'

# Customer A
$customerAName = "Customer_A"
$customerAAppVersion = "1.0.0"
$customerAPort = "3001"
$customerAFabricName = "fabric:/CustomerA"

# Customer B
$customerBName = "Customer_B"
$customerBAppVersion = "1.0.0"
$customerBPort = "3002"
$customerBFabricName = "fabric:/CustomerB"

# Customer A Version 2
$customerA2FabricName = "fabric:/CustomerA2"
$customerAAppVersion2 = "2.0.0"

$ErrorActionPreference = 'silentlycontinue'

Connect-ServiceFabricCluster -ConnectionEndpoint 'localhost:19000'

# Remove all application instances
Remove-ServiceFabricApplication -ApplicationName $customerAFabricName -Force
Remove-ServiceFabricApplication -ApplicationName $customerBFabricName -Force
Remove-ServiceFabricApplication -ApplicationName $customerA2FabricName -Force

# Unregister all application types
Unregister-ServiceFabricApplicationType -ApplicationTypeName $app1AppType -ApplicationTypeVersion $customerAAppVersion -Force
Unregister-ServiceFabricApplicationType -ApplicationTypeName $app2AppType -ApplicationTypeVersion $customerAAppVersion2 -Force
Unregister-ServiceFabricApplicationType -ApplicationTypeName $app2AppType -ApplicationTypeVersion $customerBAppVersion -Force

# Remove all application packages
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $app1Package
Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $app2Package

if($removeTraffic -eq $True)
{
    Remove-ServiceFabricApplication -ApplicationName $traefikFabricName -Force
    Unregister-ServiceFabricApplicationType -ApplicationTypeName $traefikAppType -ApplicationTypeVersion "1.0.0" -Force
    Remove-ServiceFabricApplicationPackage -ApplicationPackagePathInImageStore $traefikPackage
}

# Clean up overrides
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.priority' -Method Delete
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.rule.default' -Method Delete

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerB/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.priority' -Method Delete
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerB/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.rule.default' -Method Delete

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.priority' -Method Delete
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.frontend.rule.default' -Method Delete

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.backend.group.name' -Method Delete
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.backend.group.weight' -Method Delete

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA3/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.backend.group.name' -Method Delete
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA3/WebService/$/GetProperty?api-version=6.0&PropertyName=traefik.backend.group.weight' -Method Delete

# Delete results
rm .\results\*