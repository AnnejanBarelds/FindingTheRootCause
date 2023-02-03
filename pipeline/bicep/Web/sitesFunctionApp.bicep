param name string

param location string = resourceGroup().location

param appServicePlanResourceId string

param logAnalyticsWorkspaceResourceId string

param settings object = {}

@description('The value for the `WEBSITES_ENABLE_APP_SERVICE_STORAGE` setting. Defaults to `true`')
param websitesEnableAppServiceStorage bool = true

@description('The value for the `FUNCTIONS_EXTENSION_VERSION` setting. Defaults to `~4`')
param functionsExtensionsVersion string = '~4'

@description('The value for the `FUNCTIONS_WORKER_RUNTIME` setting. Defaults to `dotnet`')
param functionsWorkerRuntime string = 'dotnet'

param kind string = 'functionapp'

var storageAccountName = uniqueString('${name}-storage')

var functionAppSettings = {
  FUNCTIONS_EXTENSION_VERSION: functionsExtensionsVersion
  FUNCTIONS_WORKER_RUNTIME: functionsWorkerRuntime
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: websitesEnableAppServiceStorage
}

var functionStorageSettings = {
  AzureWebJobsStorage__accountName: storageAccountName
}

var storageBlobDataOwner = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageQueueDataContributor = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanResourceId
    httpsOnly: true
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostic-setting'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

module appInsights '../Insights/applicationinsights.bicep' = {
  name: '${deployment().name}-applicationInsights'
  params: {
    location: location
    appInsightsName: '${name}-ai'
    workspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

module storageAccount '../Storage/storageAccounts.bicep' = {
  name: '${deployment().name}-storageAccount'
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    storageAccountName: storageAccountName
  }
}

module blobStoragePermission '../Authorization/roleAssignmentsStorage.bicep' = {
  name: '${deployment().name}-blobStoragePermission'
  params: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataOwner
    storageAccountName: storageAccountName
  }
}

module queueStoragePermission '../Authorization/roleAssignmentsStorage.bicep' = {
  name: '${deployment().name}-queueStoragePermission'
  params: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageQueueDataContributor
    storageAccountName: storageAccountName
  }
}

module appSettings 'Sites/appsettings.bicep' = {
  name: '${deployment().name}-appSettings'
  params: {
    siteName: functionApp.name
    appInsightsName: appInsights.outputs.name
    settings: union(union(functionAppSettings, functionStorageSettings), settings)
  }
}

output principalId string = functionApp.identity.principalId
