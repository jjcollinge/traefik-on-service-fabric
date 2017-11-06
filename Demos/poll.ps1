param (
    [Parameter(Mandatory=$true)]
    [string]
    $logfile,
    [Parameter(Mandatory=$true)]
    [string]
    $uri,
    [Parameter(Mandatory=$false)]
    [int16]
    $interval
 )

$success_count = 0
$fail_count = 0

while($True) 
{ 
    try {
        $res = (Invoke-WebRequest -Uri $uri -ErrorAction Stop)
        $body = $res.Content
        $statusCode = $res.statusCode
    } catch {
        $statusCode = 404
        $body = ""
    }

    # Print call status
    echo "$body : HTTP $statusCode"

    if($statusCode -eq 200)
    {
        $success_count++
    }
    else
    {
        $fail_count++
    }

    # Print aggregate to counts to file
    $logstamp = [int64](([datetime]::UtcNow)-(get-date "1/1/1970")).TotalSeconds
    echo "T:$logstamp,U:$uri,S:$success_count,F:$fail_count" > $logfile

    # Delay polling
    Sleep $interval
}