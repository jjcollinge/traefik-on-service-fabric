Param
(
    [String]
    $ApplicationPackagePath = "TraefikApplicationPkg",

    [String]
    $ImageStoreConnectionString = "fabric:ImageStore",

    [string]
    $ApplicationVersion = "1.0.0",
	
    [hashtable]
    $ApplicationParameters = @{}
)

$ApplicationPackagePath = Join-Path $PSScriptRoot $ApplicationPackagePath

Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $ApplicationPackagePath -ImageStoreConnectionString $ImageStoreConnectionString
Register-ServiceFabricApplicationType TraefikApplicationPkg
New-ServiceFabricApplication fabric:/TraefikContainerType  TraefikContainerType  $ApplicationVersion -ApplicationParameter $ApplicationParameters
