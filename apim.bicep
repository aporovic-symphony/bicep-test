
param uaminame string = 'uami-script'
targetScope='resourceGroup'
param utcValue string = utcNow()
param location string = resourceGroup().location
param functionAppName string = 'funApp-dev-iglooNovus-app-user-inbox-service'
param serviceName string = 'UserInboxService'
param functionAppHostKeyValue string = newGuid()

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uaminame
  location: location
}

resource functionApp 'Microsoft.Web/sites@2020-12-01' existing = {
  name: functionAppName
}

resource function 'Microsoft.Web/sites/functions@2022-03-01' existing = {
  name: 'Swagger'
  parent: functionApp
}

resource apiManagementService 'Microsoft.ApiManagement/service@2019-12-01' existing = {
  name: 'apim-dev-igloonovus-bicep-test'
}

resource functionAppApimHostKey 'Microsoft.Web/sites/host/functionKeys@2018-11-01' = {
  name: '${functionAppName}/default/${apiManagementService.name}'
  properties: {
    name: apiManagementService.name
    value: functionAppHostKeyValue
  }
}

module apimHostKey 'get-host-key.bicep' = {
  name: 'apim-host-key-account-echo'
  //scope: resourceGroup(resourceGroupName)
  params: {
 
   location: location
   utcValue:  utcValue
   resourceGroup: resourceGroup().name
   functionApp: functionAppName
   apimName: apiManagementService.name
  }
}

resource apimNamedValue 'Microsoft.ApiManagement/service/namedValues@2022-04-01-preview' = {
  name: functionAppName
  parent: apiManagementService
  properties: {
    displayName: functionAppName
    secret: false
    value: functionAppHostKeyValue
  }
}

resource openApiSpec 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
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
    timeout: 'PT5M'
    arguments: '-specUrl \'${function.properties.invoke_url_template}?code=${function.listkeys().default}\''
    scriptContent: loadTextContent('fetchOpenApiSpec.ps1')
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource functionAppApi 'Microsoft.ApiManagement/service/apis@2022-04-01-preview' = {
  parent: apiManagementService
  name: '${functionAppName}Api'
  properties: {
      type: 'http'
      protocols: ['https']
      displayName: functionAppName
      path: serviceName
      format: 'openapi+json'
      value: openApiSpec.properties.outputs.Result
      subscriptionRequired: false
  }
}

resource apiServiceBackend 'Microsoft.ApiManagement/service/backends@2022-04-01-preview' = {
  name: toLower(functionAppName)
  parent: apiManagementService
  properties: {
    protocol: 'http'
    url: 'https://${functionAppName}.azurewebsites.net'
    credentials: {
      query: {
        code: ['{{${apimNamedValue.name}}}']
      }      
    }
    // https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-resource#resourceid
    //resourceId: concat('https://management.azure.com/subscriptions/', subscription().id, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Web/sites/', functionAppName))"
  } 
}

var allOperationPolicyText = replace(loadTextContent('apim-policies/alloperations.xml'), '{{ServiceName}}', serviceName)

resource AllApisPolicy 'Microsoft.ApiManagement/service/policies@2022-04-01-preview' = {
  name: 'policy'
  parent: apiManagementService
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-policies/allapis.xml')
  }
}

resource AllOperationsPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-04-01-preview' = {
  name: 'policy'
  parent: functionAppApi
  properties: {
    format: 'rawxml'
    value: allOperationPolicyText
  }
}

var operationIds = openApiSpec.properties.outputs.OperationIds

module modStorageAccount 'operation-policy.bicep' = {
  name: 'operation-policy-creation'
  //scope: resourceGroup(resourceGroupName)
  params: {
    operationIds: operationIds
    functionAppName: functionAppName
    apimName: apiManagementService.name
    apiName: functionAppApi.name
  }
}

// output operations array = apiImport.listByApi()

output spec string = openApiSpec.properties.outputs.Result
