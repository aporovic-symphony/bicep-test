param([string] $resourceUri, [string] $keyName)
Install-Module -Name Az -AllowClobber -Scope CurrentUser

$DeploymentScriptOutputs = @{}
$data = az rest --method post --uri ${resourceUri} | ConvertFrom-Json

$DeploymentScriptOutputs['key'] = $data.functionKeys.$keyName