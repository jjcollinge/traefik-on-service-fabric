<#
.SYNOPSIS 
Updates, packages and deploys an Application's Configuration

.DESCRIPTION
Updates, packages and deploys an Application's Configuration

.PARAMETER ServiceFabricConnectionEndpoint 
Endpoint address for Service Fabric connection i.e. http://localhost:19000

.PARAMETER SecureCluster 
Indicated whether or not this is a secure cluster connection

.PARAMETER PfxCertThumbprint 
Certificate thumbprint for secure cluster connection

.PARAMETER HealthCheckStableDurationSec 
Number of seconds to wait to check upgrade domain is healthy after upgrade

.PARAMETER UpgradeDomainTimeoutSec 
Number of seconds to wait for a upgrade domain to timeout

.PARAMETER UpgradeTimeout 
Number of seconds to wait for an entire upgrade to timeout

.EXAMPLE
PS> Update-Config.ps1 -ServiceFabricConnectionEndpoint $clusterfqdn:19000 -PfxCertThumbprint $Thumbprint -SecureCluster 1

.NOTES
This script expects the 'fabric:/Traefik' application
to already be deployed to the Service Fabric cluster.
It also expects the current solution versions to match
the deployed versions of the code/config/data packages.

Author: @dotjson
#>

param (
   [Parameter(Mandatory=$false)]
   [string]
   $ServiceFabricConnectionEndpoint = "localhost:19000",
   [Parameter(Mandatory=$false)]
   [string]
   $PfxCertThumbprint,
   [Parameter(Mandatory=$true)]
   [boolean]
   $SecureCluster,
   [Parameter(Mandatory=$false)]
   [int16]
   $HealthCheckStableDurationSec = 60,
   [Parameter(Mandatory=$false)]
   [int16]  
   $UpgradeDomainTimeoutSec = 1200,
   [Parameter(Mandatory=$false)]
   [int16]  
   $UpgradeTimeout = 3000
)

filter timestamp {"$(Get-Date -Format G): $_"}

if ($SecureCluster)
{
    if (-Not(Test-Path variable:PfxCertThumbprint))
    {
        Write-Host "PfxCertThumbprint must be provided when using a secure cluster endpoint"
        exit
    }
}

# Setup file system paths
$ApplicationPackageRoot = [io.Path]::Combine((Split-Path -Path $pwd.Path -Parent), "ApplicationPackageRoot")
$TraefikPackage = [io.Path]::Combine($ApplicationPackageRoot, "TraefikPkg")
$ConfigPackages = [io.Path]::Combine($ApplicationPackageRoot, "ConfigPkgs")

# Create directory to store config packages if one doesn't already exist
if ( -Not (Test-Path -LiteralPath $ConfigPackages -PathType Container))
{
	mkdir $ConfigPackages
}

# Read current service manifest
$CurrentServiceManifestPath = [io.Path]::Combine($TraefikPackage, "ServiceManifest.xml")
$CurrentServiceManifestBackupPath = $CurrentServiceManifestPath + ".bak"
Copy-Item $CurrentServiceManifestPath $CurrentServiceManifestBackupPath
[xml]$CurrentServiceManifestXML = Get-Content -Path $CurrentServiceManifestPath

# Read current application manifest
$CurrentApplicationManifestPath = [io.Path]::Combine($ApplicationPackageRoot, "ApplicationManifest.xml")
$CurrentApplicationManifestBackupPath = $CurrentApplicationManifestPath + ".bak"
Copy-Item $CurrentApplicationManifestPath $CurrentApplicationManifestBackupPath
[xml]$CurrentApplicationManifestXML = Get-Content -Path $CurrentApplicationManifestPath

Try {
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

	# Update application manifest service manifest import version
	$CurrentApplicationManifestXML.ApplicationManifest.ServiceManifestImport.FirstChild.ServiceManifestVersion = $NewSerVersion

	# Increment application manifest application type version
	$AppTypeVerMajor, $AppTypeVerMinor, $AppTypeVerPatch = $CurrentApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion.Split('.')
	$AppTypeVerPatch = [int]$AppTypeVerPatch + 1
	$NewAppTypeVer = $AppTypeVerMajor + "." + $AppTypeVerMinor + "." + $AppTypeVerPatch
	$CurrentApplicationManifestXML.ApplicationManifest.ApplicationTypeVersion = $NewAppTypeVer

	# Write updates to application manifest
	$CurrentApplicationManifestXML.Save($CurrentApplicationManifestPath)

    ################################
	# Create a new (config only) application
    # package to deploy to the Service
    # Fabric cluster
	################################

	# Create new application package
	$NewAppPkgName = "ConfigPkg" + ([int][double]::Parse((Get-Date -UFormat %s)))
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

	################################
	# Deploy new application package
    # to Service Fabric cluster
	################################

	$TraefikApplicationName = "fabric:/Traefik"
    
    
    if ($SecureCluster)
    {
        Connect-ServiceFabricCluster -ConnectionEndpoint $ServiceFabricConnectionEndpoint -X509Credential -ServerCertThumbprint $PfxCertThumbprint -FindType FindByThumbprint -FindValue $PfxCertThumbprint -StoreLocation CurrentUser -StoreName My
    } else {
        Connect-ServiceFabricCluster -ConnectionEndpoint $ServiceFabricConnectionEndpoint
    }

	Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $NewAppPkg -ApplicationPackagePathInImageStore $NewAppPkgName
	Register-ServiceFabricApplicationType -ApplicationPathInImageStore $NewAppPkgName
	Start-ServiceFabricApplicationUpgrade -ApplicationName $TraefikApplicationName -ApplicationTypeVersion $NewAppTypeVer -HealthCheckStableDurationSec $HealthCheckStableDurationSec -UpgradeDomainTimeoutSec $UpgradeDomainTimeoutSec -UpgradeTimeout $UpgradeTimeout -FailureAction Rollback -Monitored
}
Catch
{
	Write-Error "Error occured updating configuration files: $_.Execption.Message"
	Write-Output "Reverting changes..." | timestamp

	# Revert to original state by overwritting modified files with original backups
	Copy-Item $CurrentServiceManifestBackupPath $CurrentServiceManifestPath
	Copy-Item $CurrentApplicationManifestBackupPath $CurrentApplicationManifestPath
}
Finally
{
	Write-Output "Cleaning up temporary swap files" | timestamp

	# Remove backup files
	Remove-Item -Force $CurrentServiceManifestBackupPath
	Remove-Item -Force $CurrentApplicationManifestBackupPath

	Write-Output "Done." | timestamp
}
