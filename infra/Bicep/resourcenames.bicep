// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param instanceNumber string = '1'

param functionAppName1 string = 'app1'
param functionAppName2 string = 'app2'
param functionAppName3 string = 'app3'
param functionAppName4 string = 'app4'
param functionAppName5 string = 'app5'

param dataStorageNameSuffix string = 'data'

// --------------------------------------------------------------------------------
var sanitizedEnvironment  = toLower(environmentCode)
//var sanitizedAppName = replace(replace(replace(toLower('${appName}'), ' ', ''), '-', ''), '_', '')
var sanitizedAppNameInstance = replace(replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', ''), '-', '')
// var sanitizedAppInstanceNameWithDashes = replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', '')

var lowerFunctionAppName1 = replace(toLower('${sanitizedAppNameInstance}-${functionAppName1}'), ' ', '')
var lowerFunctionAppName2 = replace(toLower('${sanitizedAppNameInstance}-${functionAppName2}'), ' ', '')
var lowerFunctionAppName3 = replace(toLower('${sanitizedAppNameInstance}-${functionAppName3}'), ' ', '')
var lowerFunctionAppName4 = replace(toLower('${sanitizedAppNameInstance}-${functionAppName4}'), ' ', '')
var lowerFunctionAppName5 = replace(toLower('${sanitizedAppNameInstance}-${functionAppName5}'), ' ', '')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// --------------------------------------------------------------------------------
output appInsightsName string             = toLower('${resourceAbbreviations.insightsComponents}-${sanitizedAppNameInstance}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
output functionApp1 object = {
    name: toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName1}-${sanitizedEnvironment}')
    servicePlanName: toLower('${resourceAbbreviations.webServerFarms}-${lowerFunctionAppName1}-${sanitizedEnvironment}')
    deploymentStorageContainerName: toLower('app-package-${lowerFunctionAppName1}')
}
output functionApp2 object = {
    name: toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName2}-${sanitizedEnvironment}')
    servicePlanName: toLower('${resourceAbbreviations.webServerFarms}-${lowerFunctionAppName2}-${sanitizedEnvironment}')
    deploymentStorageContainerName: toLower('app-package-${lowerFunctionAppName2}')
}
output functionApp3 object = {
    name: toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName3}-${sanitizedEnvironment}')
    servicePlanName: toLower('${resourceAbbreviations.webServerFarms}-${lowerFunctionAppName3}-${sanitizedEnvironment}')
    deploymentStorageContainerName: toLower('app-package-${lowerFunctionAppName3}')
}
output functionApp4 object = {
    name: toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName4}-${sanitizedEnvironment}')
    servicePlanName: toLower('${resourceAbbreviations.webServerFarms}-${lowerFunctionAppName4}-${sanitizedEnvironment}')
    deploymentStorageContainerName: toLower('app-package-${lowerFunctionAppName4}')
}
output functionApp5 object = {
    name: toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName5}-${sanitizedEnvironment}')
    servicePlanName: toLower('${resourceAbbreviations.webServerFarms}-${lowerFunctionAppName5}-${sanitizedEnvironment}')
    deploymentStorageContainerName: toLower('app-package-${lowerFunctionAppName5}')
}

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string  = toLower('${resourceAbbreviations.operationalInsightsWorkspaces}-${sanitizedAppNameInstance}-${sanitizedEnvironment}')
output cosmosDatabaseName string         = toLower('${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedAppNameInstance}-${sanitizedEnvironment}')
output userAssignedIdentityName string   = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppNameInstance}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
// Key Vaults and Storage Accounts can only be 24 characters long
// Note - had to do an exception because I couldn't purge the old key vaults in prod which was in a different region...!
output keyVaultName string               = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppNameInstance}${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${sanitizedAppNameInstance}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${dataStorageNameSuffix}', 24)
// output functionApp1StorageName string    = take('${sanitizedFunctionAppName1}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp2StorageName string    = take('${sanitizedFunctionAppName2}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp3StorageName string    = take('${sanitizedFunctionAppName3}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp4StorageName string    = take('${sanitizedFunctionAppName4}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp5StorageName string    = take('${sanitizedFunctionAppName5}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
