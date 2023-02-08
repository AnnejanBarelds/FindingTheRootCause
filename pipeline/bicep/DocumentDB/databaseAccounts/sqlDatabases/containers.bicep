param location string = resourceGroup().location

@description('The full name of the database, i.e. including the account name')
param cosmosSqlDatabaseName string

param containerName string

param partitionKey object

param options object = {}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-10-15' = {
  name: '${cosmosSqlDatabaseName}/${containerName}'
  location: location
  properties: {
    resource: {
      id: containerName
      partitionKey: partitionKey
    }
    options: options
  }
}

output fullName string = container.name

output name string = substring(container.name, lastIndexOf(container.name, '/') + 1)
