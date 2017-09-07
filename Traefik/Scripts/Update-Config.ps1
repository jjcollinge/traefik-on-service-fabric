# The following script is meant to perform a config
# only in-place upgrade. This allows you to update
# just config files/values and deploy them against
# an existing code and data package.

# WARNING
# -----------------------------
# This script expects the fabric:/Traefik application
# to already be deployed. It also expects the current
# solution versions to match the deployed versions of
# the code/config/data packages.

 param (
    [Parameter(Mandatory=$false)]
    [string]
    $ServiceFabricConnectionEndpoint = "localhost:19000",
    [Parameter(Mandatory=$false)]
    [string]
    $ServiceFabricImageStore = "file:C:\SfDevCluster\Data\ImageStoreShare"
 )

#
# Setup required paths to manifest files and directories
#

$ApplicationPackageRoot = [io.Path]::Combine((Split-Path -Path $pwd.Path -Parent), "ApplicationPackageRoot")
$TraefikPackage = [io.Path]::Combine($ApplicationPackageRoot, "TraefikPkg")
$ConfigPackages = [io.Path]::Combine($ApplicationPackageRoot, "ConfigPkgs")

# Create directory to store config packages if one doesn't already exist
if ( -Not (Test-Path -LiteralPath $ConfigPackages -PathType Container))
{
	mkdir $ConfigPackages
}

#
# Update the existing config files to reflect a patched configuration
#

# Read current service manifest
$CurrentServiceManifestPath = [io.Path]::Combine($TraefikPackage, "ServiceManifest.xml")
[xml]$CurrentServiceManifestXML = Get-Content -Path $CurrentServiceManifestPath

# Increment service manifest config package patch version
$SerConfPkgVerMajor, $SerConfPkgVerMinor, $SerConfPkgVerPatch = $CurrentServiceManifestXML.ServiceManifest.ConfigPackage.Version.Split('.')
$SerConfPkgVerPatch = [int]$SerConfPkgVerPatch + 1
$NewSerConfPkgVersion = $SerConfPkgVerMajor + "." + $SerConfPkgVerMinor + "." + $SerConfPkgVerPatch
$CurrentServiceManifestXML.ServiceManifest.ConfigPackage.Version = $NewSerConfPkgVersion

# Increment service manifest patch version
$SerVerMajor, $SerVerMinor, $SerVerPatch = $CurrentServiceManifestXML.ServiceManifest.Version.Split('.')
$SerVerPatch = [int]$SerVerPatch + 1
$NewSerVersion = $SerVerMajor + "." + $SerVerMinor + "." + $SerVerPatch
$CurrentServiceManifestXML.ServiceManifest.Version = $NewSerVersion

# Write updates to service manifest
$CurrentServiceManifestXML.Save($CurrentServiceManifestPath)

# Read current application manifest
$CurrentApplicationManifestPath = [io.Path]::Combine($ApplicationPackageRoot, "ApplicationManifest.xml")
[xml]$CurrentApplicationManifestXML = Get-Content -Path $CurrentApplicationManifestPath

# Update application manifest service manifest import version
$CurrentApplicationManifestXML.ApplicationManifest.ServiceManifestImport.FirstChild.ServiceManifestVersion = $NewSerVersion

# Increment application manifest application type version
$AppTypeVerMajor, $AppTypeVerMinor, $AppTypeVerPatch = $CurrentApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion.Split('.')
$AppTypeVerPatch = [int]$AppTypeVerPatch + 1
$NewAppTypeVer = $AppTypeVerMajor + "." + $AppTypeVerMinor + "." + $AppTypeVerPatch
$CurrentApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion = $NewAppTypeVer

# Write updates to application manifest
$CurrentApplicationManifestXML.Save($CurrentApplicationManifestPath)

#
# Create a new (config only) application package to deploy to the Service Fabric cluster
#

# Create new application package
$NewAppPkgName = "ConfigPkg" + $NewAppTypeVer
$NewAppPkg = [io.Path]::Combine($ConfigPackages, $NewAppPkgName)
mkdir $NewAppPkg

# Create new service package
$NewSerPkg = [io.Path]::Combine($NewAppPkg, "TraefikPkg")
mkdir $NewSerPkg

# Copy existing service manifest to new service package
Copy-Item $CurrentServiceManifestPath $NewSerPkg

# Copy updated config package to new service package
$CurrentConfig = [io.Path]::Combine($TraefikPackage, "Config")
Copy-Item $CurrentConfig -Recurse -Container -Destination $NewSerPkg

# Copy existing application manifest to new application package
Copy-Item $CurrentApplicationManifestPath $NewAppPkg

#
# Deploy new application package to Service Fabric cluster
#

$TraefikApplicationName = "fabric:/Traefik"
Connect-ServiceFabricCluster -ConnectionEndpoint $ServiceFabricConnectionEndpoint
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $NewAppPkg -ImageStoreConnectionString $ServiceFabricImageStore -ApplicationPackagePathInImageStore $NewAppPkgName
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $NewAppPkgName
Start-ServiceFabricApplicationUpgrade -ApplicationName $TraefikApplicationName -ApplicationTypeVersion $NewAppTypeVer -HealthCheckStableDurationSec 60 -UpgradeDomainTimeoutSec 1200 -UpgradeTimeout 3000 -FailureAction Rollback -Monitored