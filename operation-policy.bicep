param operationIds array
param apiName string
param functionAppName string
param apimName string

resource apiManagementService 'Microsoft.ApiManagement/service@2019-12-01' existing = {
  name: apimName
}

resource functionAppApi 'Microsoft.ApiManagement/service/apis@2022-04-01-preview' existing = {
  name: apiName
  parent: apiManagementService
}

resource operations 'Microsoft.ApiManagement/service/apis/operations@2022-04-01-preview' existing = [for operationName in operationIds: {
  name: operationName
  parent: functionAppApi
}]

var operationPolicyText = replace(loadTextContent('apim-policies/operation.xml'), '{{FunctionAppName}}', toLower(functionAppName))

resource OperationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-04-01-preview' = [for i in range(0, length(operationIds)): {
  name: 'policy'
  parent: operations[i]
  properties: {
    format: 'rawxml'
    value: operationPolicyText
  }
}]
