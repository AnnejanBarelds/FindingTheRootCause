param name string

param topicName string

param namespaceName string

param sbResourceGroup string = ''

resource namespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: namespaceName
  scope: empty(sbResourceGroup) ? resourceGroup() : resourceGroup(sbResourceGroup)
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' existing = {
  name: topicName
  parent: namespace
}

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  name: name
  parent: topic
}

output name string = subscription.name

output id string = subscription.id
