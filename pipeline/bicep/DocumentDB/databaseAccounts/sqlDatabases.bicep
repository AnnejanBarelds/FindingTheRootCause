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

output fullName string = database.name

output name string = substring(database.name, lastIndexOf(database.name, '/') + 1)
