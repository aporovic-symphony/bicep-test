
param uaminame string = 'uami-script'
targetScope='resourceGroup'
param utcValue string = utcNow()
param location string = resourceGroup().location
param functionAppName string = 'CommentService01'


resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uaminame
  location: location
}

resource functionApp 'Microsoft.Web/sites@2020-12-01' existing = {
  name: functionAppName
}


// resource function 'Microsoft.Web/sites/functions@2022-03-01' existing = {
//   name: 'Swagger'
//   parent: service
// }

// resource apiManagement 'Microsoft.ApiManagement/service@2019-12-01' existing = {
//   name: 'apim-bicep-test-1'
// }

// resource apiManagementApi 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
//   name: 'apim-bicep-test-1/TenantService01'
//   properties: {
//     displayName: 'My Function App API'
//     serviceUrl: functionApp.properties.defaultHostName
//     path: '/api/'
//     protocols:[
//       'http'
//     ]
//   }
// }


resource functions 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'open-api-spec'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '9.1'
    timeout: 'PT3M'
    arguments: '-functionAppName \'${functionAppName}\''
    scriptContent: '''
     param([string] $functionAppName)
     $Response = func azure functionapp list-functions $functionAppName
     $DeploymentScriptOutputs = @{}
     $DeploymentScriptOutputs['Result'] = $Response.Content
     '''
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

// resource openApiSpec 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'open-api-spec'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${uami.id}': {}
//     }
//   }
//   properties: {
//     forceUpdateTag: utcValue
//     azPowerShellVersion: '9.1'
//     timeout: 'PT3M'
//     arguments: '-specUrl \'${function.listsecrets().key}\''
//     scriptContent: '''
//      param([string] $specUrl)
//      $Response = Invoke-WebRequest -Uri $specUrl
//      $DeploymentScriptOutputs = @{}
//      $DeploymentScriptOutputs['Result'] = $Response.Content
//      '''
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }

// openApiSpec.properties.outputs.Result
// output apiSpec string = openApiSpec.properties.outputs.Result

output functionsOutput string = functions.properties.outputs.Result
