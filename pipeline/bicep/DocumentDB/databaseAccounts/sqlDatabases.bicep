param cosmosDbAccountName string

param location string = resourceGroup().location

param cosmosSqlDatabaseName string

param options object = {}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-10-15' = {
  name: '${cosmosDbAccountName}/${cosmosSqlDatabaseName}'
  location: location
  properties: {
    resource: {
      id: cosmosSqlDatabaseName
    }
    options: options
  }
}

output name string = database.name
