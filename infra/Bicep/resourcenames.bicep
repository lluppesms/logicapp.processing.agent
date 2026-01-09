// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
// @allowed(['azd','gha','azdo','dev','demo','qa','stg','ct','prod'])
param environmentCode string = 'azd'
param instanceNumber string = '1'

param functionAppName1 string = 'app1'
param functionAppName2 string = 'app2'
param functionAppName3 string = 'app3'
param functionAppName4 string = 'app4'
param functionAppName5 string = 'app5'

param dataStorageNameSuffix string = 'data'
param functionStorageNameSuffix string = 'app'

// --------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentCode)
//var lowerAppName = replace(toLower(appName), ' ', '')
var lowerFunctionAppName1 = replace(toLower('${appName}-${functionAppName1}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName2 = replace(toLower('${appName}-${functionAppName2}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName3 = replace(toLower('${appName}-${functionAppName3}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName4 = replace(toLower('${appName}-${functionAppName4}-${instanceNumber}'), ' ', '')
var lowerFunctionAppName5 = replace(toLower('${appName}-${functionAppName5}-${instanceNumber}'), ' ', '')

var sanitizedFunctionAppName1 = replace(replace(replace(lowerFunctionAppName1, ' ', ''), '-', ''), '_', '')
var sanitizedFunctionAppName2 = replace(replace(replace(lowerFunctionAppName2, ' ', ''), '-', ''), '_', '')
var sanitizedFunctionAppName3 = replace(replace(replace(lowerFunctionAppName3, ' ', ''), '-', ''), '_', '')
var sanitizedFunctionAppName4 = replace(replace(replace(lowerFunctionAppName4, ' ', ''), '-', ''), '_', '')
var sanitizedFunctionAppName5 = replace(replace(replace(lowerFunctionAppName5, ' ', ''), '-', ''), '_', '')

var sanitizedAppNameWithDashes = replace(replace(toLower('${appName}-${instanceNumber}'), ' ', ''), '_', '')
var sanitizedAppName = replace(replace(replace(toLower('${appName}-${instanceNumber}'), ' ', ''), '-', ''), '_', '')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// --------------------------------------------------------------------------------
var webSiteName = environmentCode == 'prod' ? toLower(sanitizedAppNameWithDashes) : toLower('${sanitizedAppNameWithDashes}-${sanitizedEnvironment}')
output webSiteName string                = webSiteName
output webSiteAppServicePlanName string  = '${webSiteName}-${resourceAbbreviations.webServerFarms}'
output webSiteAppInsightsName string     = '${webSiteName}-${resourceAbbreviations.insightsComponents}'

// --------------------------------------------------------------------------------
output appServicePlanName string         = '${appName}-${resourceAbbreviations.webServerFarms}'
output appInsightsName string            = '${appName}-${resourceAbbreviations.insightsComponents}'

output functionApp1Name string           = toLower('${lowerFunctionAppName1}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
output functionApp2Name string           = toLower('${lowerFunctionAppName2}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
output functionApp3Name string           = toLower('${lowerFunctionAppName3}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
output functionApp4Name string           = toLower('${lowerFunctionAppName4}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
output functionApp5Name string           = toLower('${lowerFunctionAppName5}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string  = toLower('${sanitizedAppNameWithDashes}-${sanitizedEnvironment}-${resourceAbbreviations.operationalInsightsWorkspaces}')
output cosmosDatabaseName string         = toLower('${sanitizedAppName}-${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedEnvironment}')

output userAssignedIdentityName string   = toLower('${sanitizedAppName}-${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
// Key Vaults and Storage Accounts can only be 24 characters long
// Note - had to do an exception because I couldn't purge the old key vaults in prod which was in a different region...!
output keyVaultName string = environmentCode == 'prod' ? take('${sanitizedAppName}${resourceAbbreviations.keyVaultVaults}prd', 24) : take('${sanitizedAppName}${resourceAbbreviations.keyVaultVaults}-${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${sanitizedAppName}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${dataStorageNameSuffix}', 24)
output functionApp1StorageName string     = take('${sanitizedFunctionAppName1}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
output functionApp2StorageName string     = take('${sanitizedFunctionAppName2}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
output functionApp3StorageName string     = take('${sanitizedFunctionAppName3}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
output functionApp4StorageName string     = take('${sanitizedFunctionAppName4}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
output functionApp5StorageName string     = take('${sanitizedFunctionAppName5}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)
