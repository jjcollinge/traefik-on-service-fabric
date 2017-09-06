# Locate service's config package
$rootDir = Split-Path -Path $pwd.Path -Parent
$configDir = (ls $rootDir *Config* -Directory).Name
$configPath = [io.Path]::Combine($env:Fabric_Folder_Application, $configDir)

# Set sys level env variable
[Environment]::SetEnvironmentVariable("FABRIC_CONFIG_PATH", $configPath, [System.EnvironmentVariableTarget]::Machine)

# Create local symlinked config folder
cmd /c mklink config $configPath /d
