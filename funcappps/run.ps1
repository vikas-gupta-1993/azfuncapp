using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}
$rg = $Request.Query.rg

$body = "This HTTP triggered function executed successfully. Pass the name of ResourceGroup to see VM status."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}
if ($rg) {
    $statuses = Get-AzVm -ResourceGroupName $rg -status
    $body = $statuses | Select-Object Name,powerstate
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
