# Locate service's config package
$rootDir = Split-Path -Path $pwd.Path -Parent
$configDir = (ls $rootDir *Config* -Directory | Select -Last 1).Name
$configPath = [io.Path]::Combine($env:Fabric_Folder_Application, $configDir)

# Set sys level env variable
[Environment]::SetEnvironmentVariable("FABRIC_CONFIG_PATH", $configPath, [System.EnvironmentVariableTarget]::Machine)

# Check for existing symlink
if((Get-ChildItem | Where-Object { $_.Attributes -match "ReparsePoint" }).count -eq 1)
{
	# Delete existing symlink
	cmd /c rmdir config
}

# Create local symlinked config folder
cmd /c mklink config $configPath /d
