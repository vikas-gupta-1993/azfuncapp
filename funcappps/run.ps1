using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$payloadUS=@{
    login='Super manager'
    password='Wyde456Web'
}  |  ConvertTo-Json
$payloadFR=@{
    login='Super gestionnaire'
    password='Wyde456Web'
}  |  ConvertTo-Json

$envs = @{
    atus = @{
        url = "https://atus-front.francecentral.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    atfr = @{
        url = "https://atfr-front.francecentral.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadFR
    }
    accept3 = @{
        url = "https://accept3-front.francecentral.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    accept4= @{
        url = "https://accept4-front.francecentral.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadFR
    }
    accept5 = @{
        url = "https://accept5-front.centralindia.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    accept6 = @{
        url = "https://accept6-front.centralus.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    na2 = @{
        url = "https://na2-front.centralus.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    na3 = @{
        url = "https://na3-front.centralus.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
    training = @{
        url = "https://training-front.centralindia.cloudapp.azure.com/restapi/api/rest/wynauth"
        payload = $payloadUS
    }
}

$scriptBlock={
    param($url,$payload)
    $result = Invoke-RestMethod -Uri $url -method post -Body $payload -ContentType 'application/json'
    if($result.access_token) {
        write-host "received access token"
        return $result
    } else {
        write-host "Did not receive access token"
        throw "wynauth for $url failed"
    }
}

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$rg = $Request.Query.rg
if (-not $rg) {
    $rg = $Request.Body.rg
}

$envstatus = $Request.Query.envstatus
if (-not $envstatus) {
    $envstatus = $Request.Body.envstatus
}

$body = "This HTTP triggered function executed successfully. Pass the name of ResourceGroup to see VM status."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}
if ($rg) {
    $statuses = Get-AzVm -ResourceGroupName $rg -status
    $body = $statuses | Select-Object Name,powerstate
}
if ($envstatus) {
    foreach($env in $envs.Keys){
        $envname = $envs[$env]
        write-host "Calling wynauth api on: $env"
        Start-ThreadJob -name $env -ScriptBlock $scriptBlock -ArgumentList $envname.url,$envname.payload
    }
    $apioutput = @{}
    get-job | wait-job

    $jobs = Get-Job

    foreach($job in $jobs){
        $joboutput = $job | Receive-Job
        $jobname = $job.Name
        if($job.State -eq "Completed"){
            $token = $joboutput.access_token
            write-host "call was successful"
            $apioutput.Add($jobname, @{
                status = "Env is Up"
                output = "Bearer token Received: $token"
            })
        }
        if($job.State -eq "Failed") {
            $jobError = $job.ChildJobs[0].Error
            write-host "Error is: $jobError"
            $apioutput.Add($jobname, @{
                status = "Env is Down"
                Error = $jobError
            })
        }
    }
    # Test andividual job locally:
    #Start-ThreadJob -name testvik -ScriptBlock $scriptBlock -ArgumentList "https://atfr-front.francecentral.cloudapp.azure.com/restapi/api/rest/wynauth",$payloadFR
    $output = $apioutput | ConvertTo-Json
    Write-Host $output
    get-job | Remove-Job
    $body = $output
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
