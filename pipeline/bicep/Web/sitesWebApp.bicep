param name string

param location string = resourceGroup().location

param appServicePlanResourceId string

param logAnalyticsWorkspaceResourceId string

param settings object = {}

resource webApp 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  kind: 'webapp'
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
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
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

module appSettings 'Sites/appsettings.bicep' = {
  name: '${deployment().name}-appSettings'
  params: {
    siteName: webApp.name
    appInsightsName: appInsights.outputs.name
    settings: settings
  }
}

output principalId string = webApp.identity.principalId
