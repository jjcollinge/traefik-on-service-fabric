# Setup
Read-Host ">>> Setup Service Fabric cluster?"
.\setup.ps1

# start monitor
Read-Host ">>> Start monitoring?"
$CustomerAV1Results = "results/AV"
$CustomerBV1Results = "results/BV"
$PoshExe = (get-command "powershell").Source
$CustomerAV1 = Start-Process -FilePath $PoshExe -ArgumentList ".\poll.ps1", $CustomerAV1Results, "http://localhost:80/customerA", 1 -PassThru
$CustomerBV1 = Start-Process -FilePath $PoshExe -ArgumentList ".\poll.ps1", $CustomerBV1Results, "http://localhost:80/customerB", 1 -PassThru

# start A/B upgrade
Read-Host ">>> Trigger blue/green upgrade?"
.\scenarios\upgrade-bluegreen.ps1 -newUri "http://localhost:3003"

# start canary upgrade
Read-Host ">>> Trigger canary upgrade?"
.\scenarios\upgrade-canary.ps1

# Stop monitor processes
Read-Host ">>> Stop monitoring?"
Stop-Process -id $CustomerAV1.Id -ErrorAction SilentlyContinue
Stop-Process -id $CustomerBV1.Id -ErrorAction SilentlyContinue
$results = @($CustomerAV1Results,$CustomerBV1Results)
.\summarize.ps1 $results