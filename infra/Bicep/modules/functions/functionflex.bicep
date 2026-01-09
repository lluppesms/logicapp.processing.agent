// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an .NET 10 Isolated Azure Function
// See: https://github.com/Azure-Samples/azure-functions-flex-consumption-samples/blob/main/IaC/bicep/main.bicep
// ----------------------------------------------------------------------------------------------------
param functionAppName string
param functionAppServicePlanName string
param functionInsightsName string
param functionStorageAccountName string
param deploymentStorageContainerName string = ''

param customAppSettings object = {}

@allowed(['functionapp', 'functionapp,linux'])
param functionKind string = 'functionapp,linux'
param runtimeName string = 'dotnet-isolated'
param runtimeVersion string = '10.0'
@minValue(10)
@maxValue(1000)
param maximumInstanceCount int = 50
@allowed([512, 2048, 4096])
param instanceMemoryMB int = 2048

param location string = resourceGroup().location
param commonTags object = {}
param deploymentSuffix string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~functionflex.bicep' }
var azdTag = { 'azd-service-name': 'function' }
var functionTags = union(commonTags, templateTag, azdTag)

var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().name, location))
// Use provided container name from service plan module, or calculate a default
var actualDeploymentContainerName = !empty(deploymentStorageContainerName) ? deploymentStorageContainerName : 'app-package-${take(functionStorageAccountName, 32)}-${take(resourceToken, 7)}'

// --------------------------------------------------------------------------------
resource applicationInsightsResource 'Microsoft.Insights/components@2020-02-02' existing = {
  name: functionInsightsName
}
var applicationInsightsConnectionString string = applicationInsightsResource.properties.ConnectionString

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: functionStorageAccountName
}
var storagePrimaryBlobEndpoint string = storageAccountResource.properties.primaryEndpoints.blob

resource appServiceResource 'Microsoft.Web/serverfarms@2023-12-01' existing = {
  name: functionAppServicePlanName
}

var baseAppSettings = {
    AzureWebJobsStorage__accountName: functionStorageAccountName
    AzureWebJobsStorage__credential: 'managedidentity'
    AzureWebJobsStorage__blobServiceUri: 'https://${functionStorageAccountName}.blob.${environment().suffixes.storage}'
    AzureWebJobsStorage__queueServiceUri: 'https://${functionStorageAccountName}.queue.${environment().suffixes.storage}'
    AzureWebJobsStorage__tableServiceUri: 'https://${functionStorageAccountName}.table.${environment().suffixes.storage}'
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'Authorization=AAD'
}

// --------------------------------------------------------------------------------
module functionAppResource 'br/public:avm/res/web/site:0.16.0' = {
  name: 'func${functionAppName}${deploymentSuffix}'
  params: {
    name: functionAppName
    location: location
    kind: functionKind
    tags: functionTags
    managedIdentities: {
      systemAssigned: true
    }
    serverFarmResourceId: appServiceResource.id
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storagePrimaryBlobEndpoint}${actualDeploymentContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: runtimeName
        version: runtimeVersion
      }
    }
    siteConfig: {
      alwaysOn: false
    }
    configs: [{
      name: 'appsettings'
      properties: union(baseAppSettings, customAppSettings)
    }]
  }
}

// --------------------------------------------------------------------------------
output id string = functionAppResource.outputs.resourceId
output hostname string = functionAppResource.outputs.defaultHostname
output name string = functionAppName
output insightsName string = functionInsightsName
output insightsKey string = applicationInsightsResource.properties.InstrumentationKey
output storageAccountName string = functionStorageAccountName
output functionAppPrincipalId string = functionAppResource.outputs.?systemAssignedMIPrincipalId ?? ''
