// ----------------------------------------------------------------------------------------------------
// Assign roles to the service principal or a given user
// ----------------------------------------------------------------------------------------------------
// NOTE: this requires elevated permissions in the resource group
// Contributor is not enough, you need Owner or User Access Administrator
// ----------------------------------------------------------------------------------------------------
// For a list of Role Id's see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// ----------------------------------------------------------------------------------------------------

param identityPrincipalId string
@allowed(['ServicePrincipal', 'User'])
param principalType string = 'ServicePrincipal'

param registryName string = ''
// param registryResourceGroupName string = resourceGroup().name
param storageAccountName string = ''
// param storageResourceGroupName string = resourceGroup().name
param aiSearchName string = ''
// param aiSearchResourceGroupName string = resourceGroup().name
param aiServicesName string = ''
// param aiServicesResourceGroupName string = resourceGroup().name
param cosmosName string = ''
// param cosmosResourceGroupName string = resourceGroup().name
param keyVaultName string = ''
// param keyVaultResourceGroupName string = resourceGroup().name
param apimName string = ''
// param apimResourceGroupName string = resourceGroup().name
param appInsightsName string
// param appInsightsResourceGroupName string = resourceGroup().name

// ----------------------------------------------------------------------------------------------------
var roleDefinitions = loadJsonContent('../../data/roleDefinitions.json')
var addRegistryRoles = !empty(registryName)
var addStorageRoles = !empty(storageAccountName)
var addSearchRoles = !empty(aiSearchName)
var addCogServicesRoles = !empty(aiServicesName)
var addCosmosRoles = !empty(cosmosName)
var addKeyVaultRoles = !empty(keyVaultName)
var addApimRoles = !empty(apimName)
var addAppInsightsRoles = !empty(appInsightsName)

// ----------------------------------------------------------------------------------------------------
// Registry Roles
// ----------------------------------------------------------------------------------------------------
resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = if (addRegistryRoles) {
  name: registryName
  // scope: resourceGroup(registryResourceGroupName)
}
module registry_Role_AcrPull 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addRegistryRoles) {
  name: guid(registry.id, identityPrincipalId, roleDefinitions.containerregistry.acrPullRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: registry.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.containerregistry.acrPullRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to pull images from the registry ${registryName}'
    roleName: 'Acr Pull'
  }
}

// ----------------------------------------------------------------------------------------------------
// Application Insights Roles
// ----------------------------------------------------------------------------------------------------
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (addAppInsightsRoles) {
  name: appInsightsName
  // scope: resourceGroup(appInsightsResourceGroupName)
}
module appInsights_Role_MonitoringMetricsPublisher 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addAppInsightsRoles) {
  name: guid(applicationInsights.id, identityPrincipalId, roleDefinitions.appinsights.monitoringMetricsPublisherRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: applicationInsights.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.appinsights.monitoringMetricsPublisherRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be in Monitoring Metrics Publisher role ${appInsightsName}'
    roleName: 'Monitoring Metrics Publisher'
  }
}

// ----------------------------------------------------------------------------------------------------
// Storage Roles
// ----------------------------------------------------------------------------------------------------
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = if (addStorageRoles) {
  name: storageAccountName
  // scope: resourceGroup(storageResourceGroupName)
}
module storage_Role_BlobContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.blobDataContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: storageAccount.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.blobDataContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Blob'
    roleName: 'Storage Blob Data Contributor'
  }
}
module storage_Role_BlobOwner 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.blobDataOwnerRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: storageAccount.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.blobDataOwnerRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to own the storage account ${storageAccountName} Blob Data'
    roleName: 'Storage Blob Data Owner'
  }
}
module storage_Role_TableContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.tableContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: storageAccount.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.tableContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Table'
    roleName: 'Storage Table Data Contributor'
  }
}
module storage_Role_QueueContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addStorageRoles) {
  name: guid(storageAccount.id, identityPrincipalId, roleDefinitions.storage.queueDataContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: storageAccount.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.storage.queueDataContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to write to the storage account ${storageAccountName} Queue'
    roleName: 'Storage Queue Data Contributor'
  }
}

// ----------------------------------------------------------------------------------------------------
// Cognitive Services Roles
// ----------------------------------------------------------------------------------------------------
resource aiService 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' existing = if (addCogServicesRoles) {
  name: aiServicesName
  // scope: resourceGroup(aiServicesResourceGroupName)
}
module cognitiveServices_Role_OpenAIUser 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesOpenAIUserRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: aiService.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesOpenAIUserRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be OpenAI User'
    roleName: 'Cognitive Services OpenAI User'
  }
}
module cognitiveServices_Role_OpenAIContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesOpenAIContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: aiService.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesOpenAIContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be OpenAI Contributor'
    roleName: 'Cognitive Services OpenAI Contributor'
  }
}
module cognitiveServices_Role_User 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesUserRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: aiService.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesUserRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services User'
    roleName: 'Cognitive Services User'
  }
}
module cognitiveServices_Role_Contributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: aiService.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services Contributor'
    roleName: 'Cognitive Services Contributor'
  }
}
module cognitiveServices_Role_AzureAIEngineer 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addCogServicesRoles) {
  name: guid(aiService.id, identityPrincipalId, roleDefinitions.openai.cognitiveServicesAzureAIEngineerRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: aiService.id
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.openai.cognitiveServicesAzureAIEngineerRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Cognitive Services Azure AI Engineer'
    roleName: 'Cognitive Services Azure AI Engineer'
  }
}

// ----------------------------------------------------------------------------------------------------
// Search Roles
// ----------------------------------------------------------------------------------------------------
resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = if (addSearchRoles) {
  name: aiSearchName
  // scope: resourceGroup(aiSearchResourceGroupName)
}
module search_Role_IndexDataContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.indexDataContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: searchService.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.indexDataContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to use the modify search service indexes'
    roleName: 'Search Index Data Contributor'
  }
}
module search_Role_IndexDataReader 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.indexDataReaderRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: searchService.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.indexDataReaderRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to use the read search service indexes'
    roleName: 'Search Index Data Reader'
  }
}
module search_Role_ServiceContributor 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addSearchRoles) {
  name: guid(searchService.id, identityPrincipalId, roleDefinitions.search.serviceContributorRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: searchService.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.search.serviceContributorRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a search service contributor'
    roleName: 'Search Service Contributor'
  }
}

// ----------------------------------------------------------------------------------------------------
// KeyVault Roles
// ----------------------------------------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = if (addKeyVaultRoles) {
  name: keyVaultName
  //scope: resourceGroup(keyVaultNameResourceGroupName)
}
module keyVault_Role_SecretsOfficer 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addKeyVaultRoles) {
  name: guid(keyVault.id, identityPrincipalId, roleDefinitions.keyvault.secretsOfficerRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: keyVault.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.keyvault.secretsOfficerRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Key Vault Secrets Officer'
    roleName: 'Key Vault Secrets Officer'
  }
}
module keyVault_Role_SecretsUser 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addKeyVaultRoles) {
  name: guid(keyVault.id, identityPrincipalId, roleDefinitions.keyvault.secretsUserRoleId)
  params: {
    principalId: identityPrincipalId
    principalType: principalType
    resourceId: keyVault.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.keyvault.secretsUserRoleId)
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a Key Vault Secrets User'
    roleName: 'Key Vault Secrets User'
  }
}

// ----------------------------------------------------------------------------------------------------
// APIM Roles - assign to Identity running APIM
// ----------------------------------------------------------------------------------------------------
resource apimService 'Microsoft.ApiManagement/service@2024-05-01' existing = if (addApimRoles) {
  name: apimName
  //scope: resourceGroup(apimResourceGroupName)
}

module apimReaderAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (addApimRoles) {
  name: guid(apimService.id, identityPrincipalId, roleDefinitions.apim.serviceReaderRoleId)
  params: {
    principalId: identityPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.apim.serviceReaderRoleId)
    principalType: principalType
    resourceId: apimService.id
    description: 'Permission for ${principalType} ${identityPrincipalId} to be a APIM Service Reader'
    roleName: 'APIM Service Reader'
  }
}


// ----------------------------------------------------------------------------------------------------
// Cosmos ***Database*** Roles
// ----------------------------------------------------------------------------------------------------
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-08-15' existing = if (addCosmosRoles) {
  name: cosmosName
  //scope: resourceGroup(cosmosResourceGroupName)
}

resource cosmosDbUserAccessRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-08-15' = if (addCosmosRoles) {
  name: guid(cosmosAccount.id, identityPrincipalId, roleDefinitions.cosmos.dataContributorRoleId)
  parent: cosmosAccount
  properties: {
    principalId: identityPrincipalId
    roleDefinitionId: '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccount.name}/sqlRoleDefinitions/${roleDefinitions.cosmos.dataContributorRoleId}'
    scope: cosmosAccount.id
  }
}

// ----------------------------------------------------------------------------------------------------
output containerRegistryRoleAssignmentIds object = (addRegistryRoles) ? {
  registry_AcrPull_RoleId : registry_Role_AcrPull.outputs.resourceId
} : {}

output storageRoleAssignmentIds object = (addStorageRoles) ? {
  storage_BlobContributor_RoleId : storage_Role_BlobContributor.outputs.resourceId
  storage_TableContributor_RoleId : storage_Role_TableContributor.outputs.resourceId
  storage_QueueContributor_RoleId : storage_Role_QueueContributor.outputs.resourceId
} : {}

output cognitiveServicesRoleAssignmentIds object = (addCogServicesRoles) ? {
  cognitiveServices_OpenAIUser_RoleId : cognitiveServices_Role_OpenAIUser.outputs.resourceId
  cognitiveServices_OpenAIContributor_RoleId : cognitiveServices_Role_OpenAIContributor.outputs.resourceId
  cognitiveServices_User_RoleId : cognitiveServices_Role_User.outputs.resourceId
  cognitiveServices_Contributor_RoleId : cognitiveServices_Role_Contributor.outputs.resourceId
  cognitiveServices_AzureAIEngineer_RoleId : cognitiveServices_Role_AzureAIEngineer.outputs.resourceId
} : {}

output searchServiceRoleAssignmentIds object = (addSearchRoles) ? {
  search_IndexDataContributor_RoleId : search_Role_IndexDataContributor.outputs.resourceId
  search_IndexDataReader_RoleId : search_Role_IndexDataReader.outputs.resourceId
  search_ServiceContributor_RoleId : search_Role_ServiceContributor.outputs.resourceId
} : {}

output keyVaultRoleAssignmentIds object = (addKeyVaultRoles) ? {
  keyVault_SecretsOfficer_RoleId : keyVault_Role_SecretsOfficer.outputs.resourceId
  keyVault_SecretsUser_RoleId : keyVault_Role_SecretsUser.outputs.resourceId
} : {}

output cosmosRoleAssignmentIds object = (addCosmosRoles) ? {
  cosmos_UserAccess_RoleId : cosmosDbUserAccessRoleAssignment.id
} : {}
