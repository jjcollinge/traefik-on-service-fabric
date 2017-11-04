param (
    [Parameter(Mandatory=$true)]
    [string[]]
    $logFiles
 )

 echo "------------------------------"
 ForEach($logFile in $logFiles)
 {
    $content = Get-Content $logFile
    $parts = $content.Split(',')
    $timestamp = $parts[0] -replace "T" -replace "" 
    $uri = $parts[1] -replace "U" -replace "" 
    $success = $parts[2] -replace "S:" -replace ""
    $fail = $parts[3] -replace "F:" -replace ""

    echo "Timestamp: $timestamp"
    echo "Url: $uri"
    echo "Successful: $success"
    echo "Failed: $fail"
    $total = ([int]$success + [int]$fail)
    echo "Total: $total"
    echo ""
 }
 echo "------------------------------"
