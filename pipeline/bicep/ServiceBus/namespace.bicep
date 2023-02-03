param location string = resourceGroup().location

param name string

resource namespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}
