param cosmosDbName string

param location string = resourceGroup().location

param logAnalyticsWorkspaceResourceId string

@allowed(['BoundedStaleness', 'ConsistentPrefix', 'Eventual', 'Session', 'Strong'])
param defaultConsistencyLevel string = 'Session'

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: cosmosDbName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
    }
    locations: [
      {
        locationName: location
        isZoneRedundant: false
      }
    ]
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${cosmosDbName}-diagnostic-setting'
  scope: cosmosDb
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
      {
        category: 'MongoRequests'
        enabled: true
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
      {
        category: 'CassandraRequests'
        enabled: true
      }
      {
        category: 'GremlinRequests'
        enabled: true
      }
      {
        category: 'TableApiRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
}

output cosmosDbEndpoint string = cosmosDb.properties.documentEndpoint

output name string = cosmosDb.name
