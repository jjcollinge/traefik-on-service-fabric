param (
    [Parameter(Mandatory=$true)]
    [string]
    $newUri
 )

# Deploy CustomerA v2 Package CustomerA2/WebService
Connect-ServiceFabricCluster -ConnectionEndpoint 'localhost:19000' 
New-ServiceFabricApplication -ApplicationName "fabric:/CustomerA2" -ApplicationTypeName 'NodeAppType' -ApplicationTypeVersion "2.0.0" -ApplicationParameter @{Port="3003"; Response="Customer_A : 2.0.0"} -ErrorAction Stop

Read-Host ">>> Swap target?"
$statusCode = 404
while($statusCode -ne 200)
{
    try {
        $statusCode = (Invoke-WebRequest -Uri $newUri -ErrorAction Stop).StatusCode
    } catch {
        $statusCode = 404  
    }
    sleep 1
}

# Change the priority of v2 to higher than v1
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.priority",
  "Value": {
    "Kind": "String",
    "Data": "70"
  },
  "CustomTypeId": "LabelType"
}'

# Remove staging route
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.frontend.rule.default",
  "Value": {
    "Kind": "String",
    "Data": "PathPrefixStrip: /customerA"
  },
  "CustomTypeId": "LabelType"
}'
