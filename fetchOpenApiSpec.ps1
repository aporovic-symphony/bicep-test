param([string] $specUrl)
$DeploymentScriptOutputs = @{}
[System.Collections.ArrayList]$operationIds = @()
$openApiSpec = Invoke-WebRequest -Uri $specUrl
$openApiSpecObj = ConvertFrom-Json -InputObject $openApiSpec

$ignoreParameters = "code", "Endpoints", "TenantId"

foreach ($path in $openApiSpecObj.paths.PSObject.Properties) {
    foreach ($method in $path.Value.PSObject.Properties) {
        $methodObj = $method.Value
        $operationIds.Add($methodObj.operationId)
        [array]$methodObj.parameters = $methodObj.parameters | Where-Object {!($ignoreParameters.Contains($_.name))}
        if ($null -eq $methodObj.parameters)
        {
            $methodObj.PSObject.Properties.Remove('parameters')
        }
    }
}

$DeploymentScriptOutputs['Result'] = ConvertTo-Json -Compress $openApiSpecObj -Depth 20
$DeploymentScriptOutputs['OperationIds'] = $operationIds