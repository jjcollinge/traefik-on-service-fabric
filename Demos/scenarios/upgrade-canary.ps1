
# Deploy CustomerA v3 Package CustomerA3/WebService
Connect-ServiceFabricCluster -ConnectionEndpoint 'localhost:19000'
New-ServiceFabricApplication -ApplicationName "fabric:/CustomerA3" -ApplicationTypeName 'NodeAppType' -ApplicationTypeVersion "3.0.0" -ApplicationParameter @{Port="3004"; Response="Customer_A : 3.0.0"} -ErrorAction Stop

# Update CusotmerA v2 Properties to add to same canary group as v3
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.name",
  "Value": {
    "Kind": "String",
    "Data": "Canary"
  },
  "CustomTypeId": "LabelType"
}' > $null

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "100"
  },
  "CustomTypeId": "LabelType"
}' > $null

Read-Host ">>> Set v3 distribution to 25%?"
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "75"
  },
  "CustomTypeId": "LabelType"
}' > $null

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA3/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "25"
  },
  "CustomTypeId": "LabelType"
}' > $null

Read-Host ">>> Set v3 distribution to 50%?"
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "50"
  },
  "CustomTypeId": "LabelType"
}' > $null

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA3/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "50"
  },
  "CustomTypeId": "LabelType"
}' > $null

Read-Host ">>> Set v3 distribution to 100%?"
Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA2/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "0"
  },
  "CustomTypeId": "LabelType"
}' > $null

Invoke-WebRequest -Uri 'http://localhost:19080/Names/CustomerA3/WebService/$/GetProperty?api-version=6.0&IncludeValues=true' -Method Put -Body '{
  "PropertyName": "traefik.backend.group.weight",
  "Value": {
    "Kind": "String",
    "Data": "100"
  },
  "CustomTypeId": "LabelType"
}' > $null