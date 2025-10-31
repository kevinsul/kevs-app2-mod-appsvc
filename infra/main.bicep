targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Resource group name')
param resourceGroupName string = 'rg-${environmentName}'

@description('SQL Administrator login')
@secure()
param sqlAdminPassword string = newGuid()

// Tags
var tags = {
  'azd-env-name': environmentName
}

// Resource token for unique naming
var resourceToken = uniqueString(subscription().id, location, environmentName)

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Virtual Network
module vnet './core/network/vnet.bicep' = {
  name: 'vnet-${resourceToken}'
  scope: rg
  params: {
    name: 'vnet-${resourceToken}'
    location: location
    tags: tags
  }
}

// Log Analytics Workspace
module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'loganalytics-${resourceToken}'
  scope: rg
  params: {
    name: 'azlog${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights './core/monitor/applicationinsights.bicep' = {
  name: 'appinsights-${resourceToken}'
  scope: rg
  params: {
    name: 'azai${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// User-assigned managed identity
module managedIdentity './core/identity/userassignedidentity.bicep' = {
  name: 'identity-${resourceToken}'
  scope: rg
  params: {
    name: 'azid${resourceToken}'
    location: location
    tags: tags
  }
}

// Key Vault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault-${resourceToken}'
  scope: rg
  params: {
    name: 'azkv${resourceToken}'
    location: location
    tags: tags
    principalId: managedIdentity.outputs.principalId
  }
}

// SQL Server and Database
module sqlServer './core/database/sqlserver.bicep' = {
  name: 'sqlserver-${resourceToken}'
  scope: rg
  params: {
    name: 'azsql${resourceToken}'
    location: location
    tags: tags
    databaseName: 'InventoryDB'
    sqlAdminPassword: sqlAdminPassword
    keyVaultName: keyVault.outputs.name
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}

// Private Endpoint for SQL Server
module sqlPrivateEndpoint './core/network/private-endpoint.bicep' = {
  name: 'sqlpe-${resourceToken}'
  scope: rg
  params: {
    name: 'pe-sql-${resourceToken}'
    location: location
    tags: tags
    subnetId: vnet.outputs.privateEndpointSubnetId
    privateLinkServiceId: sqlServer.outputs.id
    groupIds: [
      'sqlServer'
    ]
  }
}

// Private DNS Zone for SQL Server
module sqlPrivateDnsZone './core/network/private-dns-zone.bicep' = {
  name: 'sqldns-${resourceToken}'
  scope: rg
  params: {
    name: 'privatelink.database.windows.net'
    tags: tags
    vnetId: vnet.outputs.id
    privateEndpointId: sqlPrivateEndpoint.outputs.id
  }
}

// App Service Plan and App Service
module appService './core/host/appservice.bicep' = {
  name: 'appservice-${resourceToken}'
  scope: rg
  params: {
    name: 'azapp${resourceToken}'
    location: location
    tags: tags
    serviceTag: 'web'
    appServicePlanName: 'azplan${resourceToken}'
    managedIdentityId: managedIdentity.outputs.id
    managedIdentityClientId: managedIdentity.outputs.clientId
    applicationInsightsConnectionString: appInsights.outputs.connectionString
    keyVaultName: keyVault.outputs.name
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    sqlConnectionString: 'Server=tcp:${sqlServer.outputs.serverName},1433;Initial Catalog=${sqlServer.outputs.databaseName};User ID=sqladmin;Password=${sqlAdminPassword};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    vnetIntegrationSubnetId: vnet.outputs.appServiceIntegrationSubnetId
  }
  dependsOn: [
    sqlPrivateDnsZone // Ensure DNS is ready before app service tries to connect
  ]
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_ID string = rg.id
output RESOURCE_GROUP_NAME string = rg.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output WEB_APP_NAME string = appService.outputs.name
output WEB_APP_URI string = appService.outputs.uri
output MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.outputs.clientId
output MANAGED_IDENTITY_PRINCIPAL_ID string = managedIdentity.outputs.principalId
output SQL_SERVER_NAME string = sqlServer.outputs.serverName
output SQL_DATABASE_NAME string = sqlServer.outputs.databaseName
output VNET_NAME string = vnet.outputs.name
output VNET_ID string = vnet.outputs.id
