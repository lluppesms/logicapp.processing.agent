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
    // environmentSpecificFunctionName: ''
  }
}
// --------------------------------------------------------------------------------
module logAnalyticsWorkspaceModule 'modules/monitor/loganalytics.bicep' = {
  name: 'logAnalytics${deploymentSuffix}'
  params: {
    newLogAnalyticsName: resourceNames.outputs.logAnalyticsWorkspaceName
    newWebApplicationInsightsName: resourceNames.outputs.webSiteAppInsightsName
    // newFunctionApplicationInsightsName: '' // No longer deploying functions
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
    // storageAccountName: '' // No function storage needed
  }
}

module adminUserRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments && !empty(principalId)) {
  name: 'user-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: principalId
    principalType: 'User'
    cosmosName: cosmosModule.outputs.name
    keyVaultName: keyVaultModule.outputs.name
    // storageAccountName: '' // No function storage needed
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

// // --------------------------------------------------------------------------------
// // Service Plan for webapp and function
// // --------------------------------------------------------------------------------
// module appServicePlanModule './modules/webapp/websiteserviceplan.bicep' = {
//   name: 'appServicePlan${deploymentSuffix}'
//   params: {
//     location: location
//     commonTags: commonTags
//     sku: servicePlanSku
//     environmentCode: environmentCode
//     appServicePlanName: servicePlanName == '' ? resourceNames.outputs.webSiteAppServicePlanName : servicePlanName
//     existingServicePlanName: servicePlanName
//     existingServicePlanResourceGroupName: servicePlanResourceGroupName
//     webAppKind: servicePlanKind
//   }
// }

// --------------------------------------------------------------------------------
// Function Flex Consumption - Shared Infrastructure (App Service Plan, App Insights, Storage)
// This is deployed once and shared by all function apps
// --------------------------------------------------------------------------------
module functionFlexServicePlanModule 'modules/functions/functionserviceplan.bicep' = {
  name: 'functionFlexServicePlan${deploymentSuffix}'
  params: {
    functionAppServicePlanName: resourceNames.outputs.functionFlexAppServicePlanName
    functionInsightsName: resourceNames.outputs.functionFlexInsightsName
    functionStorageAccountName: resourceNames.outputs.functionFlexStorageName
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceId
    deploymentSuffix: deploymentSuffix
  }
}

// --------------------------------------------------------------------------------
// Function App 1 - Main Processing Function
// --------------------------------------------------------------------------------
module functionFlexApp1Module 'modules/functions/functionflex.bicep' = {
  name: 'functionFlexApp1${deploymentSuffix}'
  params: {
    functionAppName: resourceNames.outputs.functionFlexAppName
    functionAppServicePlanName: functionFlexServicePlanModule.outputs.appServicePlanName
    functionInsightsName: functionFlexServicePlanModule.outputs.appInsightsName
    functionStorageAccountName: functionFlexServicePlanModule.outputs.storageAccountName
    deploymentStorageContainerName: functionFlexServicePlanModule.outputs.deploymentStorageContainerName
    location: location
    commonTags: commonTags
    deploymentSuffix: deploymentSuffix
    customAppSettings: {
      CosmosDb__Endpoint: 'https://${cosmosModule.outputs.name}.documents.azure.com:443/'
      CosmosDb__ConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
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

// Role assignments for Function App 1
module functionFlexApp1RoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'functionFlexApp1-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: functionFlexApp1Module.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
    appInsightsName: functionFlexServicePlanModule.outputs.appInsightsName
    storageAccountName: functionFlexServicePlanModule.outputs.storageAccountName
    keyVaultName: keyVaultModule.outputs.name
  }
}

// --------------------------------------------------------------------------------
// Function App 2 - Acceptor Function (Cosmos DB triggered intake processor)
// --------------------------------------------------------------------------------
module acceptorFunctionAppModule 'modules/functions/functionflex.bicep' = {
  name: 'acceptorFunctionApp${deploymentSuffix}'
  params: {
    functionAppName: resourceNames.outputs.acceptorFunctionAppName
    functionAppServicePlanName: functionFlexServicePlanModule.outputs.appServicePlanName
    functionInsightsName: functionFlexServicePlanModule.outputs.appInsightsName
    functionStorageAccountName: functionFlexServicePlanModule.outputs.storageAccountName
    deploymentStorageContainerName: functionFlexServicePlanModule.outputs.deploymentStorageContainerName
    location: location
    commonTags: commonTags
    deploymentSuffix: deploymentSuffix
    customAppSettings: {
      CosmosDb__Endpoint: 'https://${cosmosModule.outputs.name}.documents.azure.com:443/'
      CosmosDb__ConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
      CosmosDb__DatabaseName: cosmosDatabaseName
      CosmosDb__ContainerNames__Requests: processRequestsContainerName
      CosmosDb__ContainerNames__ProcessTypes: processTypesContainerName
      // Settings for Function with Cosmos trigger -- no sub levels
      CosmosDbDatabaseName: cosmosDatabaseName
      CosmosDbContainerName: processRequestsContainerName
      CosmosDbConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
    }
  }
}

// Role assignments for Acceptor Function App
module acceptorFunctionAppRoleAssignments './modules/iam/role-assignments.bicep' = if (addRoleAssignments) {
  name: 'acceptorFunctionApp-roles${deploymentSuffix}'
  params: {
    identityPrincipalId: acceptorFunctionAppModule.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
    appInsightsName: functionFlexServicePlanModule.outputs.appInsightsName
    storageAccountName: functionFlexServicePlanModule.outputs.storageAccountName
    keyVaultName: keyVaultModule.outputs.name
    cosmosName: cosmosModule.outputs.name
  }
}

// // --------------------------------------------------------------------------------
// module webSiteModule './modules/webapp/website.bicep' = {
//   name: 'webSite${deploymentSuffix}'
//   params: {
//     webSiteName: resourceNames.outputs.webSiteName
//     location: location
//     commonTags: commonTags
//     environmentCode: environmentCode
//     webAppKind: servicePlanKind
//     managedIdentityId: identity.outputs.managedIdentityId
//     managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
//     workspaceId: logAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceId
//     appServicePlanName: appServicePlanModule.outputs.name
//     appServicePlanResourceGroupName: appServicePlanModule.outputs.resourceGroupName
//     sharedAppInsightsInstrumentationKey: logAnalyticsWorkspaceModule.outputs.webAppInsightsInstrumentationKey
//   }
// }

// // In a Linux app service, any nested JSON app key like AppSettings:MyKey needs to be
// // configured in App Service as AppSettings__MyKey for the key name.
// // In other words, any : should be replaced by __ (double underscore).
// // NOTE: See https://learn.microsoft.com/en-us/azure/app-service/configure-common?tabs=portal
// module webSiteAppSettingsModule './modules/webapp/websiteappsettings.bicep' = {
//   name: 'webSiteAppSettings${deploymentSuffix}'
//   params: {
//     webAppName: webSiteModule.outputs.name
//     appInsightsKey: logAnalyticsWorkspaceModule.outputs.webAppInsightsInstrumentationKey
//     customAppSettings: {
//       AppSettings__AppInsights_InstrumentationKey: logAnalyticsWorkspaceModule.outputs.webAppInsightsInstrumentationKey
//       AppSettings__EnvironmentName: environmentCode
//       ConnectionStrings__ApplicationInsights: logAnalyticsWorkspaceModule.outputs.webAppInsightsConnectionString
//       // Cosmos DB settings (now configured directly in web app)
//       CosmosDb__Endpoint: 'https://${cosmosModule.outputs.name}.documents.azure.com:443/'
//       CosmosDb__ConnectionString: '@Microsoft.KeyVault(SecretUri=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
//       CosmosDb__DatabaseName: cosmosDatabaseName
//       CosmosDb__ContainerNames__Requests: processRequestsContainerName
//       CosmosDb__ContainerNames__ProcessTypes: processTypesContainerName
//       // Settings for Function with Cosmos trigger -- no sub levels
//       CosmosDbDatabaseName: cosmosDatabaseName
//       CosmosDbContainerName: processRequestsContainerName
//       CosmosDbConnectionString: '@Microsoft.KeyVault(SecretUri=${keyVaultSecretCosmos.outputs.connectionStringSecretName})'
//       // OpenAI settings (now configured directly in web app)
//       OpenAI__Chat__DeploymentName: OpenAI_DeploymentName
//       OpenAI__Chat__Endpoint: OpenAI_Endpoint
//       OpenAI__Chat__ApiKey: '@Microsoft.KeyVault(SecretUri=${keyVaultSecretOpenAI.outputs.secretUri})'
//       OpenAI__Chat__ModelName: OpenAI_ModelName
//       OpenAI__Chat__Temperature: OpenAI_Temperature
//     }
//   }
// }

// --------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_NAME string = resourceGroupName
output FUNCTION1_HOST_NAME string = functionFlexApp1Module.outputs.hostname
output ACCEPTOR_FUNCTION_HOST_NAME string = acceptorFunctionAppModule.outputs.hostname
//output WEB_HOST_NAME string = webSiteModule.outputs.hostName
