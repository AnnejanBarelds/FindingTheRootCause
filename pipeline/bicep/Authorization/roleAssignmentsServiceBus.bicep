param principalId string

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
  'ForeignGroup'
  'Device'
])
param principalType string

param serviceBusNamespaceName string

@description('''
Specify a value for `queueName` if the role assignment should be scoped to a queue
''')
param queueName string = ''

@description('''
Specify a value for `topicName` if the role assignment should be scoped to a topic or a subscription
This value is ignored if `queueName` is also specified. To apply a role to both a queue and a topic, call this module twice
''')
param topicName string = ''

@description('''
Specify a value for `subscriptionName` if the role assignment should be scoped to a subscription; `topicName` should also be specified
This value is ignored if `queueName` is also specified. To apply a role to both a queue and a subscription, call this module twice
''')
param subscriptionName string = ''

param roleDefinitionId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusNamespaceName
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' existing = {
  name: queueName
  parent: serviceBusNamespace
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: topicName
  parent: serviceBusNamespace
}

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' existing = {
  name: subscriptionName
  parent: topic
}

resource roleAssignmentQueue 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(!empty(queueName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleDefinitionId)
  scope: queue
  properties: {
    principalId: principalId
    roleDefinitionId: '/subscriptions/${az.subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}'
    principalType: principalType
  }
}

resource roleAssignmentTopic 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && !empty(topicName) && empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleDefinitionId)
  scope: topic
  properties: {
    principalId: principalId
    roleDefinitionId: '/subscriptions/${az.subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}'
    principalType: principalType
  }
}

resource roleAssignmentSubscription 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && !empty(topicName) && !empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleDefinitionId)
  scope: subscription
  properties: {
    principalId: principalId
    roleDefinitionId: '/subscriptions/${az.subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}'
    principalType: principalType
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(empty(queueName) && empty(topicName) && empty(subscriptionName)) {
  name: guid(serviceBusNamespace.id, queueName, topicName, subscriptionName, principalId, roleDefinitionId)
  scope: serviceBusNamespace
  properties: {
    principalId: principalId
    roleDefinitionId: '/subscriptions/${az.subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}'
    principalType: principalType
  }
}
