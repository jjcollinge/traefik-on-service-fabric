# In order to update the configuration
# for an existing service you need to
# create a package that only contains
# the following files:
#
# ApplicationManifest.xml
# ServiceManifest.xml
# Config/...
#
# Perform the following updates on these files
#
# ApplicationManifest.xml
#	- ApplicationTypeVersion
#	- ServiceManifestImport -> ServiceManifestRef -> SeviceManifestVersion 
# ServiceManifest.xml
#	- Version
#	- ConfigPackage -> Version

# Setup paths
$ApplicationPackageRoot = [io.Path]::Combine((Split-Path -Path $pwd.Path -Parent), "ApplicationPackageRoot")
$TraefikPackage = [io.Path]::Combine($ApplicationPackageRoot, "TraefikPkg")
$ConfigPackages = [io.Path]::Combine($ApplicationPackageRoot, "ConfigPkgs")

# Create directory to store config packages if one doesn't already exist
if ( -Not (Test-Path -LiteralPath $ConfigPackages -PathType Container))
{
	mkdir $ConfigPackages
}

# Read in existing configuration
$CurrentServiceManifestPath = [io.Path]::Combine($TraefikPackage, "ServiceManifest.xml")
[xml]$CurrentServiceManifestXML = Get-Content -Path $CurrentServiceManifestPath
$CurrentConfigVersion = $CurrentServiceManifestXML.ServiceManifest.ConfigPackage.Version

# Create new config package
$Major, $Minor, $Patch = $CurrentConfigVersion.Split('.')
$IncrementedPatch = [int]$Patch + 1
$NewConfigVersion = $Major + "." + $Minor + "." + $IncrementedPatch
$NewPackageName = "ConfigPkg" + $NewConfigVersion
$NewPackage = [io.Path]::Combine($ConfigPackages, $NewPackageName)
mkdir $NewPackage
$NewServicePackage = [io.Path]::Combine($NewPackage, "TraefikPkg")
mkdir $NewServicePackage

# Copy existing config into package
Copy-Item $CurrentServiceManifestPath $NewServicePackage
$CurrentApplicationManifest = [io.Path]::Combine($ApplicationPackageRoot, "ApplicationManifest.xml")
Copy-Item $CurrentApplicationManifest $NewPackage

# Copy new config folder into package
$CurrentConfig = [io.Path]::Combine($TraefikPackage, "Config")
Copy-Item $CurrentConfig -Recurse -Container -Destination $NewServicePackage

# Read service manifest
$NewServiceManifestPath = [io.Path]::Combine($NewServicePackage, "ServiceManifest.xml")
[xml]$NewServiceManifestXML = Get-Content -Path $NewServiceManifestPath

# Update service manifest version
$SerVerMajor, $SerVerMinor, $SerVerPatch = $NewServiceManifestXML.ServiceManifest.Version.Split('.')
$IncremenetedSerVerPatch = [int]$SerVerPatch + 1
$NewSerVer = $SerVerMajor + "." + $SerVerMinor + "." + $IncremenetedSerVerPatch
$NewServiceManifestXML.ServiceManifest.Version = $NewSerVer

# Update service manifest code package version
$NewServiceManifestXML.ServiceManifest.ConfigPackage.Version = $NewSerVer
$NewServiceManifestXML.Save($NewServiceManifestPath)

# Read application manifest
$NewApplicationManifestPath = [io.Path]::Combine($NewPackage, "ApplicationManifest.xml")
[xml]$NewApplicationManifestXML = Get-Content -Path $NewApplicationManifestPath

# Update application manifest type version
$AppVerMajor, $AppVerMinor, $AppVerPatch = $NewApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion.Split('.')
$IncremenetedAppVerPatch = [int]$AppVerPatch + 1
$NewAppVer = $AppVerMajor + "." + $AppVerMinor + "." + $IncremenetedAppVerPatch
$NewApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion = $NewAppVer

# Update appliction manifest service manifest import version
$NewApplicationManifestXML.ApplicationManifest.ServiceManifestImport.FirstChild.ServiceManifestVersion = $NewSerVer
$NewApplicationManifestXML.Save($NewApplicationManifestPath)

# Deploy package to Service Fabric Cluster
$ServiceFabricImageStore = "file:C:\SfDevCluster\Data\ImageStoreShare"
$TraefikApplicationName = "fabric:/Traefik"
Connect-ServiceFabricCluster -ConnectionEndpoint localhost:19000
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $NewPackage -ImageStoreConnectionString $ServiceFabricImageStore -ApplicationPackagePathInImageStore $NewPackageName
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $NewPackageName
Start-ServiceFabricApplicationUpgrade -ApplicationName $TraefikApplicationName -ApplicationTypeVersion $NewConfigVersion -HealthCheckStableDurationSec 60 -UpgradeDomainTimeoutSec 1200 -UpgradeTimeout 3000 -FailureAction Rollback -Monitored