// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Logic App Standard (Workflow)
// ----------------------------------------------------------------------------------------------------
param logicAppName string
param logicAppServicePlanName string
param appInsightsName string
param storageAccountName string

@description('SKU name for App Service Plan')
param appServicePlanSkuName string = 'WS1'

@description('SKU tier for App Service Plan')
param appServicePlanTier string = 'WorkflowStandard'

param customAppSettings object = {}

param addRoleAssignments bool = true
param keyVaultName string

param location string = resourceGroup().location
param commonTags object = {}
param deploymentSuffix string = ''

// Cosmos DB and Office 365 connection parameters
param cosmosDbAccountName string
param cosmosDbDatabaseName string
param cosmosDbContainerName string
param adminEmailAddress string = 'admin@example.com'

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~logicapp.bicep' }
var azdTag = { 'azd-service-name': 'logicapp' }
var logicAppTags = union(commonTags, templateTag, azdTag)

// --------------------------------------------------------------------------------
resource applicationInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}
var applicationInsightsConnectionString = applicationInsightsResource.properties.ConnectionString

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// --------------------------------------------------------------------------------
// App Service Plan for Logic App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: logicAppServicePlanName
  location: location
  tags: logicAppTags
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanTier
  }
  properties: {}
}

// --------------------------------------------------------------------------------
// Managed Identity for Logic App
resource logicAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${logicAppName}-identity'
  location: location
  tags: logicAppTags
}

// --------------------------------------------------------------------------------
// Logic App Standard (Workflow)
resource logicApp 'Microsoft.Web/sites@2023-12-01' = {
  name: logicAppName
  location: location
  tags: logicAppTags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${logicAppIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountResource.id, '2023-01-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'WORKFLOWS_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
          value: resourceGroup().name
        }
        {
          name: 'WORKFLOWS_LOCATION_NAME'
          value: location
        }
        {
          name: 'WORKFLOWS_TENANT_ID'
          value: subscription().tenantId
        }
        {
          name: 'WORKFLOWS_LOGIC_APP_NAME'
          value: logicAppName
        }
        {
          name: 'CosmosDbDatabaseName'
          value: cosmosDbDatabaseName
        }
        {
          name: 'CosmosDbContainerName'
          value: cosmosDbContainerName
        }
        {
          name: 'AdminEmailAddress'
          value: adminEmailAddress
        }
      ]
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
}

// --------------------------------------------------------------------------------
// Cosmos DB API Connection
resource cosmosDbConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azurecosmosdb-${logicAppName}'
  location: location
  tags: logicAppTags
  properties: {
    displayName: 'Cosmos DB Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'documentdb')
    }
    parameterValues: {
      databaseAccount: cosmosDbAccountName
    }
  }
}

// --------------------------------------------------------------------------------
// Office 365 API Connection
resource office365Connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365-${logicAppName}'
  location: location
  tags: logicAppTags
  properties: {
    displayName: 'Office 365 Outlook Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
  }
}

// --------------------------------------------------------------------------------
// Grant Logic App access to Cosmos DB connection
resource cosmosDbConnectionAccessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '${cosmosDbConnection.name}/${logicAppIdentity.name}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: logicAppIdentity.properties.principalId
      }
    }
  }
}

// --------------------------------------------------------------------------------
// Grant Logic App access to Office 365 connection
resource office365ConnectionAccessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '${office365Connection.name}/${logicAppIdentity.name}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: logicAppIdentity.properties.principalId
      }
    }
  }
}

// --------------------------------------------------------------------------------
// Outputs
output logicAppName string = logicApp.name
output logicAppId string = logicApp.id
output logicAppIdentityPrincipalId string = logicAppIdentity.properties.principalId
output cosmosDbConnectionId string = cosmosDbConnection.id
output cosmosDbConnectionName string = cosmosDbConnection.name
output office365ConnectionId string = office365Connection.id
output office365ConnectionName string = office365Connection.name
output hostname string = logicApp.properties.defaultHostName
