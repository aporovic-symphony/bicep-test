param uaminame string = 'uami-script'
param location string
param utcValue string = utcNow()
param subscriptionId string = '6dffb2a7-1054-40fe-8ef4-ddcb61d54fe6'
param resourceGroup string
param functionApp string
param apimName string


var resourceId = '/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.Web/sites/${functionApp}'
var resourceUri = '${resourceId}/host/default/listKeys?api-version=2018-11-01'

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uaminame
  location: location
}

// resource hostKey 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'function-app-host-keys'
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
//     timeout: 'PT5M'
//     arguments: '-resourceUri \'${resourceUri}\' -keyName \'${apimName}\''
//     scriptContent: loadTextContent('fetchFunAppHostKey.ps1')
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }

resource hostKey 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'function-app-host-keys-echo'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uami.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azCliVersion: '2.40.0'
    timeout: 'PT30M'
    arguments: '\'${resourceUri}\' \'${apimName}\''
    environmentVariables: []
    scriptContent: loadTextContent('azscript.sh')
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output key string = hostKey.properties.outputs.Result
