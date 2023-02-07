targetScope = 'subscription'

param location string = deployment().location

var AzureServiceBusDataReceiver = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

var AzureServiceBusDataSender = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'

var CosmosDbBuiltInDataContributorRoleId = '00000000-0000-0000-0000-000000000002'
var CosmosDbBuiltInDataReaderRoleId = '00000000-0000-0000-0000-000000000001'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'RootCause'
  location: location
}

module appPlan 'Web/serverFarm.bicep' = {
  scope: rg
  name: '${deployment().name}-appPlan'
  params: {
    name: 'appAsp'
    location: location
    sku: {
      name: 'F1'
    }
    logAnalyticsWorkspaceResourceId: law.outputs.id
  }
}

module functionPlan 'Web/serverFarm.bicep' = {
  scope: rg
  name: '${deployment().name}-functionPlan'
  params: {
    name: 'functionAsp'
    location: location
    logAnalyticsWorkspaceResourceId: law.outputs.id
  }
}

module app 'Web/sitesWebApp.bicep' = {
  scope: rg
  name: '${deployment().name}-app'
  params: {
    location: location
    appServicePlanResourceId: appPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'app-rootcause'
  }
}

module appApi 'Web/sitesFunctionApp.bicep' = {
  scope: rg
  name: '${deployment().name}-appApi'
  params: {
    location: location
    appServicePlanResourceId: functionPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'api-rootcause'
    kind: 'functionapp'
    settings: {
      ServiceBusConnectionString__fullyQualifiedNamespace: '${serviceBus.name}.servicebus.windows.net'
      OrderTopic: orderTopic.outputs.name
    }
  }
}

module orderProcessor 'Web/sitesFunctionApp.bicep' = {
  scope: rg
  name: '${deployment().name}-orderProcessor'
  params: {
    location: location
    appServicePlanResourceId: functionPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'orderProcessor-rootcause'
    kind: 'functionapp'
    settings: {
      ServiceBusConnectionString__fullyQualifiedNamespace: '${serviceBus.name}.servicebus.windows.net'
      OrderTopic: orderTopic.outputs.name
      OrderProcessingSubscription: orderProcessingSub.outputs.name
      CosmosDbConnection__accountEndpoint: cosmosDb.outputs.cosmosDbEndpoint
      CosmosDbConnection__credential: 'managedidentity'
    }
  }
}

module customerLoyaltyProcessor 'Web/sitesFunctionApp.bicep' = {
  scope: rg
  name: '${deployment().name}-customerLoyaltyProcessor'
  params: {
    location: location
    appServicePlanResourceId: functionPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'customerLoyaltyProcessor-rootcause'
    kind: 'functionapp'
    settings: {
      ServiceBusConnectionString__fullyQualifiedNamespace: '${serviceBus.name}.servicebus.windows.net'
      OrderTopic: orderTopic.outputs.name
      CustomerLoyaltySubscription: customerLoyaltySub.outputs.name
    }
  }
}

module orderFulfillmentProcessor 'Web/sitesFunctionApp.bicep' = {
  scope: rg
  name: '${deployment().name}-orderFulfillmentProcessor'
  params: {
    location: location
    appServicePlanResourceId: functionPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'orderFulfillmentProcessor-rootcause'
    kind: 'functionapp'
    settings: {
      CosmosDbConnection__accountEndpoint: cosmosDb.outputs.cosmosDbEndpoint
      CosmosDbConnection__credential: 'managedidentity'
    }
  }
}

module inventoryApi 'Web/sitesFunctionApp.bicep' = {
  scope: rg
  name: '${deployment().name}-inventoryApi'
  params: {
    location: location
    appServicePlanResourceId: functionPlan.outputs.id
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: 'inventoryApi-rootcause'
    kind: 'functionapp'
    settings: {
      
    }
  }
}

module law 'OperationalInsights/workspace.bicep' = {
  scope: rg
  name: '${deployment().name}-law'
  params: {
    location: location
    name: 'law-rootcause'
  }
}

module orderTopic 'ServiceBus/Topics/topic.bicep' = {
  name: '${deployment().name}-topic'
  scope: resourceGroup('ServiceBus')
  params: {
    name: 'orderTopic-rootcause'
    namespaceName: serviceBus.name
    sbResourceGroup: 'ServiceBus'
  }
}

module orderProcessingSub 'ServiceBus/Topics/Subscriptions/subscription.bicep' = {
  name: '${deployment().name}-orderProcessingSub'
  scope: resourceGroup('ServiceBus')
  params: {
    name: 'orderProcessingSub-rootcause'
    topicName: orderTopic.outputs.name
    namespaceName: serviceBus.name
    sbResourceGroup: 'ServiceBus'
  }
}

module customerLoyaltySub 'ServiceBus/Topics/Subscriptions/subscription.bicep' = {
  name: '${deployment().name}-customerLoyaltySub'
  scope: resourceGroup('ServiceBus')
  params: {
    name: 'customerLoyaltySub-rootcause'
    topicName: orderTopic.outputs.name
    namespaceName: serviceBus.name
    sbResourceGroup: 'ServiceBus'
  }
}

module sendPermission 'Authorization/roleAssignmentsServiceBus.bicep' = {
  name: '${deployment().name}-sbSendPermission'
  scope: resourceGroup('ServiceBus')
  params: {
    principalId: appApi.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: AzureServiceBusDataSender
    serviceBusNamespaceName: serviceBus.name
    topicName: orderTopic.outputs.name
  }
}

module customerLoyaltyReceivePermission 'Authorization/roleAssignmentsServiceBus.bicep' = {
  name: '${deployment().name}-sbCustomerLoyaltyReceivePermission'
  scope: resourceGroup('ServiceBus')
  params: {
    principalId: customerLoyaltyProcessor.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: AzureServiceBusDataReceiver
    serviceBusNamespaceName: serviceBus.name
    topicName: orderTopic.outputs.name
    subscriptionName: customerLoyaltySub.outputs.name
  }
}

module orderProcessorReceivePermission 'Authorization/roleAssignmentsServiceBus.bicep' = {
  name: '${deployment().name}-sbOrderProcessorReceivePermission'
  scope: resourceGroup('ServiceBus')
  params: {
    principalId: orderProcessor.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: AzureServiceBusDataReceiver
    serviceBusNamespaceName: serviceBus.name
    topicName: orderTopic.outputs.name
    subscriptionName: orderProcessingSub.outputs.name
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: 'annejan'
  scope: resourceGroup('ServiceBus')
}

module cosmosDb 'DocumentDB/databaseAccounts.bicep' = {
  name: '${deployment().name}-cosmosDb'
  scope: rg
  params: {
    location: location
    cosmosDbName: 'cosmos-rootcause'
    logAnalyticsWorkspaceResourceId: law.outputs.id
  }
}

module cosmosSqlDatabase 'DocumentDB/databaseAccounts/sqlDatabases.bicep' = {
  scope: rg
  name: '${deployment().name}-cosmosSqlDatabase'
  params: {
    cosmosDbAccountName: cosmosDb.outputs.name
    cosmosSqlDatabaseName: 'Events'
    location: location
    options: {
      throughput: 400
    }
  }
}

module cosmosEventContainer 'DocumentDB/databaseAccounts/sqlDatabases/containers.bicep' = {
  scope: rg
  name: '${deployment().name}-cosmosEventContainer'
  params: {
    cosmosSqlDatabaseName: cosmosSqlDatabase.outputs.name
    location: location
    containerName: 'OrderEvents'
    partitionKey: {
      paths: [
        '/OrderId'
      ]
    }
  }
}

module cosmosLeaseContainer 'DocumentDB/databaseAccounts/sqlDatabases/containers.bicep' = {
  scope: rg
  name: '${deployment().name}-cosmosLeaseContainer'
  params: {
    cosmosSqlDatabaseName: cosmosSqlDatabase.outputs.name
    location: location
    containerName: 'Leases'
    partitionKey: {
      paths: [
        '/id'
      ]
    }
  }
}

module cosmosEventWritePermission 'DocumentDB/databaseAccounts/sqlRoleAssignments.bicep' = {
  name: '${deployment().name}-orderProcessorCosmosPermission'
  scope: rg
  params: {
    cosmosDbName: cosmosDb.outputs.name
    principalId: orderProcessor.outputs.principalId
    roleDefinitionId: CosmosDbBuiltInDataContributorRoleId
    scope: {
      database: cosmosSqlDatabase.outputs.name
      container: cosmosEventContainer.outputs.name
    }
  }
}

module cosmosEventReadPermission 'DocumentDB/databaseAccounts/sqlRoleAssignments.bicep' = {
  name: '${deployment().name}-orderFulfillCosmosReadPermission'
  scope: rg
  params: {
    cosmosDbName: cosmosDb.outputs.name
    principalId: orderFulfillmentProcessor.outputs.principalId
    roleDefinitionId: CosmosDbBuiltInDataReaderRoleId
    scope: {
      database: cosmosSqlDatabase.outputs.name
      container: cosmosEventContainer.outputs.name
    }
  }
  dependsOn: [
   cosmosEventWritePermission 
  ]
}

module cosmosLeaseWritePermission 'DocumentDB/databaseAccounts/sqlRoleAssignments.bicep' = {
  name: '${deployment().name}-orderFulfillCosmosWritePermission'
  scope: rg
  params: {
    cosmosDbName: cosmosDb.outputs.name
    principalId: orderFulfillmentProcessor.outputs.principalId
    roleDefinitionId: CosmosDbBuiltInDataContributorRoleId
    scope: {
      database: cosmosSqlDatabase.outputs.name
      container: cosmosLeaseContainer.outputs.name
    }
  }
  dependsOn: [
    cosmosEventReadPermission
  ]
}
