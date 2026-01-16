// --------------------------------------------------------------------------------
// Main Bicep file that creates all of the Azure Resources for one environment
// After refactoring: Web App now handles all game logic directly without Azure Functions
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
//   az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n "manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --resource-group rg_lapagent_test --template-file 'main.bicep' --parameters appName=xxx-lapagent-test environmentCode=demo keyVaultOwnerUserId=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param location string = resourceGroup().location
param instanceNumber string = '1'
// param servicePlanName string = ''
// param servicePlanResourceGroupName string = '' // if using an existing service plan in a different resource group
// param servicePlanKind string = 'linux' // 'linux' or 'windows'
// param servicePlanSku string = 'B1'

// --------------------------------------------------------------------------------
// AI Foundry Parameters
// --------------------------------------------------------------------------------
param OpenAI_Endpoint string
@secure()
param OpenAI_ApiKey string
param OpenAI_DeploymentName string = 'gpt-5-mini'
param OpenAI_ModelName string = 'gpt_5_mini'
param OpenAI_Temperature string = '0.8'

// --------------------------------------------------------------------------------
// Run Settings Parameters
// --------------------------------------------------------------------------------
@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true
@description('Should resources be created with public access?')
// param publicAccessEnabled bool = true
// @description('Should we deploy Cosmos DB?')
param deployCosmos bool = true

// --------------------------------------------------------------------------------
// Personal info Parameters
// --------------------------------------------------------------------------------
// @description('My IP address for network access')
// param myIpAddress string = ''
@description('Id of the user executing the deployment')
param principalId string = ''

// --------------------------------------------------------------------------------
// Misc. Parameters
// --------------------------------------------------------------------------------
// calculated variables disguised as parameters
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {
  LastDeployed: runDateTime
  Application: appName
  Environment: environmentCode
}
var resourceGroupName = resourceGroup().name
// var resourceToken = toLower(uniqueString(resourceGroup().id, location))

// --------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
    instanceNumber: instanceNumber
    functionAppName1: 'intake'
    functionAppName2: 'accept'
    functionAppName3: 'process'
    functionAppName4: 'receive'
    functionAppName5: 'analyze'
  }
}
// --------------------------------------------------------------------------------
module logAnalyticsWorkspaceModule 'modules/monitor/loganalytics.bicep' = {
  name: 'logAnalytics${deploymentSuffix}'
  params: {
    newLogAnalyticsName: resourceNames.outputs.logAnalyticsWorkspaceName
    newWebApplicationInsightsName: resourceNames.outputs.appInsightsName
    location: location
    tags: commonTags
  }
}

// --------------------------------------------------------------------------------
var cosmosDatabaseName = 'lapagent-data-${environmentCode}'
var processRequestsContainerName = 'ProcessRequests'
var processTypesContainerName = 'ProcessTypes'
var cosmosContainerArray = [
  { name: processRequestsContainerName, partitionKey: '/id' }
  { name: processTypesContainerName, partitionKey: '/id' }
]
module cosmosModule 'modules/database/cosmosdb.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    accountName: deployCosmos ? resourceNames.outputs.cosmosDatabaseName : ''
    // if this is no, then use the existing cosmos so you don't have to wait 20 minutes every time...
    existingAccountName: deployCosmos ? '' : resourceNames.outputs.cosmosDatabaseName
    location: location
    tags: commonTags
    containerArray: cosmosContainerArray
    databaseName: cosmosDatabaseName
  }
}

// --------------------------------------------------------------------------------
// -- Identity and Access Resources ------------------------------------------------
// --------------------------------------------------------------------------------
module identity './modules/iam/identity.bicep' = {
  name: 'app-identity${deploymentSuffix}'
  params: {
    identityName: resourceNames.outputs.userAssignedIdentityName
    location: location
  }
}

module appIdentityRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'identity-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: identity.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    cosmosName: cosmosModule.outputs.name
    keyVaultName: keyVaultModule.outputs.name
    storageAccountName: flexFunctionResourcesModule.outputs.storageAccountName
  }
}

module adminUserRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments && !empty(principalId)) {
  name: 'user-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: principalId
    principalType: 'User'
    cosmosName: cosmosModule.outputs.name
    keyVaultName: keyVaultModule.outputs.name
    storageAccountName: flexFunctionResourcesModule.outputs.storageAccountName
  }
}

// --------------------------------------------------------------------------------
module keyVaultModule './modules/security/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    // keyVaultOwnerUserId: principalId
    // keyVaultOwnerIpAddress: myIpAddress
    location: location
    commonTags: commonTags
    adminUserObjectIds: [ principalId ]
    applicationUserObjectIds: [ identity.outputs.managedIdentityPrincipalId ]
    workspaceId: logAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceId
    publicNetworkAccess: 'Enabled'
    //allowNetworkAccess: 'Allow'
    useRBAC: true
  }
}

module keyVaultSecretAppInsights './modules/security/keyvault-secret.bicep' = {
  name: 'keyVaultSecretAppInsights${deploymentSuffix}'
  dependsOn: [ keyVaultModule, logAnalyticsWorkspaceModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'webAppInsightsInstrumentationKey'
    secretValue: logAnalyticsWorkspaceModule.outputs.webAppInsightsInstrumentationKey
  }
}

module keyVaultSecretCosmos './modules/security/keyvault-cosmos-secret.bicep' = {
  name: 'keyVaultSecretCosmos${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    accountKeySecretName: 'cosmosAccountKey'
    connectionStringSecretName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.name
  }
}

module keyVaultSecretOpenAI './modules/security/keyvault-secret.bicep' = {
  name: 'keyVaultSecretOpenAI${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'openAIApiKey'
    secretValue: OpenAI_ApiKey
  }
}

// --------------------------------------------------------------------------------
// Function Flex Consumption - Shared Infrastructure (App Service Plan, App Insights, Storage)
// This is deployed once and shared by all function apps
// --------------------------------------------------------------------------------
module flexFunctionResourcesModule 'modules/functions/functionresources.bicep' = {
  name: 'flexFunctionResources${deploymentSuffix}'
  params: {
    functionInsightsName: resourceNames.outputs.appInsightsName
    functionStorageAccountName: resourceNames.outputs.storageAccountName
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceId
  }
}

// --------------------------------------------------------------------------------
// Flex Function App 1 - Main Processing Function - Intake Processor
// --------------------------------------------------------------------------------
module functionApp1FlexModule 'modules/functions/functionflex.bicep' = {
  name: 'flexFunction1${deploymentSuffix}'
  params: {
    functionAppName: resourceNames.outputs.functionApp1.name
    functionAppServicePlanName: resourceNames.outputs.functionApp1.servicePlanName
    deploymentStorageContainerName: resourceNames.outputs.functionApp1.deploymentStorageContainerName
    functionInsightsName: flexFunctionResourcesModule.outputs.appInsightsName
    functionStorageAccountName: flexFunctionResourcesModule.outputs.storageAccountName
    addRoleAssignments: addRoleAssignments
    appInsightsName: flexFunctionResourcesModule.outputs.appInsightsName
    storageAccountName: flexFunctionResourcesModule.outputs.storageAccountName
    keyVaultName: keyVaultModule.outputs.name
    location: location
    commonTags: commonTags
    deploymentSuffix: deploymentSuffix
    customAppSettings: {
      CosmosDb__Endpoint: 'https://${cosmosModule.outputs.name}.documents.azure.com:443/'
      CosmosDb__ConnectionString__Unused: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
      CosmosDb__DatabaseName: cosmosDatabaseName
      CosmosDb__ContainerNames__Requests: processRequestsContainerName
      CosmosDb__ContainerNames__ProcessTypes: processTypesContainerName
      // Settings for Function with Cosmos trigger -- no sub levels
      CosmosDbDatabaseName: cosmosDatabaseName
      CosmosDbContainerName: processRequestsContainerName
      CosmosDbConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
      // OpenAI settings
      OpenAI__Chat__DeploymentName: OpenAI_DeploymentName
      OpenAI__Chat__Endpoint: OpenAI_Endpoint
      OpenAI__Chat__ApiKey: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretOpenAI.outputs.secretName})'
      OpenAI__Chat__ModelName: OpenAI_ModelName
      OpenAI__Chat__Temperature: OpenAI_Temperature
    }
  }
}

// --------------------------------------------------------------------------------
// Logic App - Acceptor Workflow (Cosmos DB triggered intake processor)
// --------------------------------------------------------------------------------
module logicAppModule 'modules/logicapp/logicapp.bicep' = {
  name: 'logicApp${deploymentSuffix}'
  params: {
    logicAppName: resourceNames.outputs.functionApp2.name
    logicAppServicePlanName: resourceNames.outputs.functionApp2.servicePlanName
    appInsightsName: flexFunctionResourcesModule.outputs.appInsightsName
    storageAccountName: flexFunctionResourcesModule.outputs.storageAccountName
    addRoleAssignments: addRoleAssignments
    keyVaultName: keyVaultModule.outputs.name
    location: location
    commonTags: commonTags
    deploymentSuffix: deploymentSuffix
    cosmosDbAccountName: cosmosModule.outputs.name
    cosmosDbDatabaseName: cosmosDatabaseName
    cosmosDbContainerName: processRequestsContainerName
    adminEmailAddress: 'admin@example.com'
    customAppSettings: {
      CosmosDb__Endpoint: 'https://${cosmosModule.outputs.name}.documents.azure.com:443/'
      CosmosDb__ConnectionString__Unused: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
      CosmosDb__DatabaseName: cosmosDatabaseName
      CosmosDb__ContainerNames__Requests: processRequestsContainerName
      CosmosDb__ContainerNames__ProcessTypes: processTypesContainerName
    }
  }
}

// --------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_NAME string = resourceGroupName
output INTAKE_HOST_NAME string = functionApp1FlexModule.outputs.hostname
output ACCEPTOR_LOGICAPP_HOST_NAME string = logicAppModule.outputs.hostname
