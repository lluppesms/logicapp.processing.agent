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
var sanitizedAppName      = replace(replace(replace(toLower('${appName}-${instanceNumber}'), ' ', ''), '-', ''), '_', '')
var lowerFunctionAppName1 = replace(toLower('${appName}-${functionAppName1}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName2 = replace(toLower('${appName}-${functionAppName2}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName3 = replace(toLower('${appName}-${functionAppName3}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName4 = replace(toLower('${appName}-${functionAppName4}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName5 = replace(toLower('${appName}-${functionAppName5}-${instanceNumber}'), ' ', '')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// --------------------------------------------------------------------------------
output appServicePlanName string         = toLower('${resourceAbbreviations.webServerFarms}-${sanitizedAppName}-${instanceNumber}-${sanitizedEnvironment}')
output appInsightsName string            = toLower('${resourceAbbreviations.insightsComponents}-${sanitizedAppName}-${instanceNumber}-${sanitizedEnvironment}')

output functionApp1Name string           = toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName1}-${sanitizedEnvironment}')
output functionApp2Name string           = toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName2}-${sanitizedEnvironment}')
output functionApp3Name string           = toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName3}-${sanitizedEnvironment}')
output functionApp4Name string           = toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName4}-${sanitizedEnvironment}')
output functionApp5Name string           = toLower('${resourceAbbreviations.functionApp}-${lowerFunctionAppName5}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string  = toLower('${resourceAbbreviations.operationalInsightsWorkspaces}-${sanitizedAppName}-${instanceNumber}-${sanitizedEnvironment}')
output cosmosDatabaseName string         = toLower('${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedAppName}-${instanceNumber}-${sanitizedEnvironment}')
output userAssignedIdentityName string   = toLower('${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedAppName}-${instanceNumber}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
// Key Vaults and Storage Accounts can only be 24 characters long
// Note - had to do an exception because I couldn't purge the old key vaults in prod which was in a different region...!
output keyVaultName string = take('${resourceAbbreviations.keyVaultVaults}${sanitizedAppName}${instanceNumber}${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${resourceAbbreviations.storageStorageAccounts}${sanitizedAppName}${instanceNumber}${sanitizedEnvironment}${dataStorageNameSuffix}', 24)
// output functionApp1StorageName string     = take('${sanitizedFunctionAppName1}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp2StorageName string     = take('${sanitizedFunctionAppName2}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp3StorageName string     = take('${sanitizedFunctionAppName3}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp4StorageName string     = take('${sanitizedFunctionAppName4}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
// output functionApp5StorageName string     = take('${sanitizedFunctionAppName5}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
