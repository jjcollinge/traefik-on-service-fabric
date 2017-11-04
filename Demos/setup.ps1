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

# Application3 package
$app3Package = 'apps\app1\v3.0.0'
$app3AppType = 'NodeAppType'
$app3ServiceName = 'WebService'
$app3ServiceType = 'WebServicePkg'

# Traefik package
$traefikPackage = 'traefik'
$traefikAppType = 'TraefikType'
$traefikServiceType = 'TraefikType'

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

$cwd = (Get-Location).Path

# Connect to cluster
echo "Connecting to cluster"
Connect-ServiceFabricCluster -ConnectionEndpoint 'localhost:19000'

$ErrorActionPreference = 'silentlycontinue'

#################################################
# Setup Traefik
#################################################

# Upload Traefik application package to the local image store
echo "Uploading application package: $traefikPackage"
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $traefikPackage -ImageStoreConnectionString 'file:C:\SfDevCluster\Data\ImageStoreShare' -ApplicationPackagePathInImageStore $traefikPackage

# Register Traefik type with the cluster
echo "Registering application type: $traefikAppType"
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $traefikPackage

# Create Traefik instance
echo "Creating Traefik application instance and default service"
New-ServiceFabricApplication -ApplicationName "fabric:/Traefik" -ApplicationTypeName $traefikAppType -ApplicationTypeVersion "1.0.0"

#################################################
# Setup Customer A Version 1
#################################################

# Upload application package to the local image store
echo "Uploading application package: $app1Package"
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath "$cwd\$app1Package" -ImageStoreConnectionString 'file:C:\SfDevCluster\Data\ImageStoreShare' -ApplicationPackagePathInImageStore $app1Package

# Register the application type with the cluster
echo "Registering application type: $app1AppType"
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $app1Package

# Create Customer A's application instance
echo "Creating Customer A's application instance"
New-ServiceFabricApplication -ApplicationName $customerAFabricName -ApplicationTypeName $app1AppType -ApplicationTypeVersion $customerAAppVersion -ApplicationParameter @{Port=$customerAPort; Response="$customerAName : $customerAAppVersion"} -ErrorAction Stop

#################################################
# Setup Customer A Version 2
#################################################

# Upload application package to the local image store
echo "Uploading application package: $app2Package"
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath "$cwd\$app2Package" -ImageStoreConnectionString 'file:C:\SfDevCluster\Data\ImageStoreShare' -ApplicationPackagePathInImageStore $app2Package

# Register the application type with the cluster
echo "Registering application type: $app2AppType"
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $app2Package

#################################################
# Setup Customer A Version 3
#################################################

# Upload application package to the local image store
echo "Uploading application package: $app3Package"
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath "$cwd\$app3Package" -ImageStoreConnectionString 'file:C:\SfDevCluster\Data\ImageStoreShare' -ApplicationPackagePathInImageStore $app3Package

# Register the application type with the cluster
echo "Registering application type: $app3AppType"
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $app3Package

#################################################
# Setup Customer B Version 1
#################################################

# Create Customer B's application instance
echo "Creating Customer B's application instance"
New-ServiceFabricApplication -ApplicationName $customerBFabricName -ApplicationTypeName $app1AppType -ApplicationTypeVersion $customerBAppVersion -ApplicationParameter @{Port=$customerBPort; Response="$customerBName : $customerBAppVersion"} -ErrorAction Stop

echo "Setup has been successfully configured"

#################################################
# Setup Customer A Version 1 default routes
#################################################

# Override the exisitng default rule
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.rule.default",
  "Value": {
    "Kind": "String",
    "Data": "PathPrefixStrip: /customerA"
  },
  "CustomTypeId": "LabelType"
}' > $null

sleep 2

# Set CustomA rule to high priority
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.priority",
  "Value": {
    "Kind": "String",
    "Data": "50"
  },
  "CustomTypeId": "LabelType"
}' > $null

#################################################
# Setup Customer B Version 1 default routes
#################################################

# Override the exisitng default rule
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerB/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.rule.default",
  "Value": {
    "Kind": "String",
    "Data": "PathPrefixStrip: /customerB"
  },
  "CustomTypeId": "LabelType"
}' > $null

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerB/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.priority",
  "Value": {
    "Kind": "String",
    "Data": "50"
  },
  "CustomTypeId": "LabelType"
}' > $null