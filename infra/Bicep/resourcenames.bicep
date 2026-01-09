// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
// @allowed(['azd','gha','azdo','dev','demo','qa','stg','ct','prod'])
param environmentCode string = 'azd'

// param functionStorageNameSuffix string = 'func'
// param functionFlexStorageNameSuffix string = 'flex'
param functionAppName1 string = 'app1'
param functionAppName2 string = 'app2'
param functionAppName3 string = 'app3'
param functionAppName4 string = 'app4'

//param environmentSpecificFunctionName string = ''
param dataStorageNameSuffix string = 'data'
param functionStorageNameSuffix string = 'app'

// --------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentCode)
//var lowerAppName = replace(toLower(appName), ' ', '')
var lowerFunctionAppName1 = replace(toLower(functionAppName1), ' ', '')
var lowerFunctionAppName2 = replace(toLower(functionAppName2), ' ', '')
var lowerFunctionAppName3 = replace(toLower(functionAppName3), ' ', '')
var lowerFunctionAppName4 = replace(toLower(functionAppName4), ' ', '')
var sanitizedAppNameWithDashes = replace(replace(toLower(appName), ' ', ''), '_', '')
var sanitizedAppName = replace(replace(replace(toLower(appName), ' ', ''), '-', ''), '_', '')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/abbreviation.json')

// --------------------------------------------------------------------------------
var webSiteName = environmentCode == 'prod' ? toLower(sanitizedAppNameWithDashes) : toLower('${sanitizedAppNameWithDashes}-${sanitizedEnvironment}')
output webSiteName string                = webSiteName
output webSiteAppServicePlanName string  = '${webSiteName}-${resourceAbbreviations.webServerFarms}'
output webSiteAppInsightsName string     = '${webSiteName}-${resourceAbbreviations.insightsComponents}'

var functionApp1Name = toLower('${lowerFunctionAppName1}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
var functionApp2Name = toLower('${lowerFunctionAppName2}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
var functionApp3Name = toLower('${lowerFunctionAppName3}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
var functionApp4Name = toLower('${lowerFunctionAppName4}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')

output functionApp1Name string            = functionApp1Name
output functionApp1ServicePlanName string = '${functionApp1Name}-${resourceAbbreviations.webServerFarms}'
output functionApp1InsightsName string    = '${functionApp1Name}-${resourceAbbreviations.webSitesAppService}'
output functionApp1StorageName string     = take('${functionApp1Name}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)

output functionApp2Name string            = functionApp2Name
output functionApp2ServicePlanName string = '${functionApp2Name}-${resourceAbbreviations.webSitesAppService}'
output functionApp2InsightsName string    = '${functionApp2Name}-${resourceAbbreviations.insightsComponents}'
output functionApp2StorageName string     = take('${functionApp2Name}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)

output functionApp3Name string            = functionApp3Name
output functionApp3ServicePlanName string = '${functionApp3Name}-${resourceAbbreviations.webSitesAppService}'
output functionApp3InsightsName string    = '${functionApp3Name}-${resourceAbbreviations.insightsComponents}'
output functionApp3StorageName string     = take('${functionApp3Name}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)

output functionApp4Name string            = functionApp4Name
output functionApp4ServicePlanName string = '${functionApp4Name}-${resourceAbbreviations.webSitesAppService}'
output functionApp4InsightsName string    = '${functionApp4Name}-${resourceAbbreviations.insightsComponents}'
output functionApp4StorageName string     = take('${functionApp4Name}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${functionStorageNameSuffix}', 24)

output logAnalyticsWorkspaceName string  = toLower('${sanitizedAppNameWithDashes}-${sanitizedEnvironment}-${resourceAbbreviations.operationalInsightsWorkspaces}')
output cosmosDatabaseName string         = toLower('${sanitizedAppName}-${resourceAbbreviations.documentDBDatabaseAccounts}-${sanitizedEnvironment}')

output userAssignedIdentityName string   = toLower('${sanitizedAppName}-${resourceAbbreviations.managedIdentityUserAssignedIdentities}-${sanitizedEnvironment}')

// Key Vaults and Storage Accounts can only be 24 characters long
// Note - had to do an exception because I couldn't purge the old key vaults in prod which was in a different region...!
output keyVaultName string = environmentCode == 'prod' ? take('${sanitizedAppName}${resourceAbbreviations.keyVaultVaults}prd', 24) : take('${sanitizedAppName}${resourceAbbreviations.keyVaultVaults}-${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${sanitizedAppName}${resourceAbbreviations.storageStorageAccounts}${sanitizedEnvironment}${dataStorageNameSuffix}', 24)
