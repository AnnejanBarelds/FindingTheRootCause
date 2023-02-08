param roleDefinitionId string
param principalId string

@description('''
If provided, scope should be an object with 2 keys:
- `database` contains the name of the database to which to apply the role assignment
- `container` contains the name of the container to which to apply the role assignment. Must be a container inside the provided `database`. Omit `container` to apply role assignment scoped to the `database`
Omit the `scope` parameter entirely to scope the role assignment to the entire CosmosDb account
''')
param scope object = { }

param cosmosDbName string

var scopevar = union({
  database: json('null')
  container: json('null')
}, scope)
var scopeSuffix = (!empty(scopevar.database) && !empty(scopevar.container)) ? '/dbs/${substring(scopevar.database, lastIndexOf(scopevar.database, '/') + 1)}/colls/${substring(scopevar.container, lastIndexOf(scopevar.container, '/') + 1)}' : (!empty(scopevar.database) && empty(scopevar.container)) ? '/dbs/${substring(scopevar.database, lastIndexOf(scopevar.database, '/') + 1)}' : ''

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' existing = {
  name: cosmosDbName
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-11-15-preview' = {
  name: guid(cosmosDb.id, scopeSuffix, principalId, roleDefinitionId)
  parent: cosmosDb
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDb.name, roleDefinitionId)
    scope: '${cosmosDb.id}${scopeSuffix}'
  }
}
