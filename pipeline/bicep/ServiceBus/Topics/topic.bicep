param name string

param namespaceName string

param sbResourceGroup string = ''

resource namespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: namespaceName
  scope: empty(sbResourceGroup) ? resourceGroup() : resourceGroup(sbResourceGroup)
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  name: name
  parent: namespace
}

output name string = topic.name

output id string = topic.id
