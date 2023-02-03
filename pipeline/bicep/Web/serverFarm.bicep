param location string = resourceGroup().location

param name string

param logAnalyticsWorkspaceResourceId string

param sku object = {
  name: 'Y1'
  tier: 'Dynamic'
}

param kind string = 'windows'

param reserved bool = false

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: sku
  kind: kind
  properties: {
    reserved: reserved
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostic-setting'
  scope: appServicePlan
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = appServicePlan.id
