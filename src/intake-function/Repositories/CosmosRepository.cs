using Microsoft.Azure.Cosmos;

namespace Processor.Agent.Intake.Repositories;

public class CosmosRepository : ICosmosRepository
{
    private readonly Container _requestsContainer;
    private readonly Container _processTypesContainer;
    private readonly ILogger<CosmosRepository> _logger;
    private string databaseName = string.Empty;
    private string requestsContainerName = string.Empty;
    private string processTypesContainerName = string.Empty;

    public CosmosRepository(CosmosClient cosmosClient, IConfiguration configuration, ILogger<CosmosRepository> logger)
    {
        _logger = logger;
        _logger.Log(LogLevel.Information, "CosmosDbService.Init: Starting");

        databaseName = configuration["CosmosDb:DatabaseName"] ?? throw new InvalidOperationException("CosmosDb:DatabaseName not configured");
        requestsContainerName = configuration["CosmosDb:RequestsContainerName"] ?? "ProcessRequests";
        processTypesContainerName = configuration["CosmosDb:ProcessTypesContainerName"] ?? "ProcessTypes";
        _logger.Log(LogLevel.Information, $"Database Name: {databaseName} Requests Container: {requestsContainerName} ProcessTypes Container: {processTypesContainerName}");

        cosmosClient.CreateDatabaseIfNotExistsAsync(databaseName).GetAwaiter().GetResult();
        var database = cosmosClient.GetDatabase(databaseName);

        database.CreateContainerIfNotExistsAsync(requestsContainerName, "/id").GetAwaiter().GetResult();
        _requestsContainer = database.GetContainer(requestsContainerName);

        database.CreateContainerIfNotExistsAsync(processTypesContainerName, "/id").GetAwaiter().GetResult();
        _processTypesContainer = database.GetContainer(processTypesContainerName);

        _logger.Log(LogLevel.Information, "CosmosDbService.Init: Complete!");
    }

    public async Task<ProcessRequest> CreateRequestAsync(ProcessRequest request)
    {
        try
        {
            var response = await _requestsContainer.CreateItemAsync(request, new PartitionKey(request.Id));

            _logger.LogInformation($"  Created Cosmos {requestsContainerName} with ID: {request.Id}");
            return response.Resource;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error creating request in Cosmos DB: {ex.Message}");
            throw;
        }
    }

    public async Task<IEnumerable<ProcessType>> GetProcessTypesAsync()
    {
        try
        {
            var query = new QueryDefinition("SELECT * FROM c WHERE c.isActive = @isActive").WithParameter("@isActive", true);
            var iterator = _processTypesContainer.GetItemQueryIterator<ProcessType>(query);

            var results = new List<ProcessType>();
            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                results.AddRange(response);
            }

            _logger.LogInformation($"  Retrieved {results.Count} active process types");
            return results;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error retrieving process types from Cosmos DB: {ex.Message}");
            throw;
        }
    }
    public static DefaultAzureCredential GetCredentials()
    {
        return GetCredentials(string.Empty, string.Empty);
    }

    public static DefaultAzureCredential GetCredentials(string visualStudioTenantId)
    {
        return GetCredentials(visualStudioTenantId, string.Empty);
    }

    public static DefaultAzureCredential GetCredentials(string visualStudioTenantId, string userAssignedManagedIdentityClientId)
    {
        if (!string.IsNullOrEmpty(visualStudioTenantId))
        {
            var azureCredential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                VisualStudioTenantId = visualStudioTenantId,
                Diagnostics = { IsLoggingContentEnabled = true }
            });
            return azureCredential;
        }
        else
        {
            if (!string.IsNullOrEmpty(userAssignedManagedIdentityClientId))
            {
                var azureCredential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                {
                    ManagedIdentityClientId = userAssignedManagedIdentityClientId,
                    Diagnostics = { IsLoggingContentEnabled = true }
                });
                return azureCredential;
            }
            else
            {
                var azureCredential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                {
                    Diagnostics = { IsLoggingContentEnabled = true }
                });
                return azureCredential;
            }
        }
    }
}
