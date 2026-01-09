namespace Processor.Agent.Intake.Repositories;

public class CosmosRepository : ICosmosRepository
{
    private readonly CosmosClient _cosmosClient;
    private readonly Container _requestsContainer;
    private readonly Container _processTypesContainer;
    private readonly ILogger<CosmosRepository> _logger;

    public CosmosRepository(IConfiguration configuration, ILogger<CosmosRepository> logger)
    {
        _logger = logger;

        var accountEndpoint = configuration["CosmosDb:AccountEndpoint"] ?? throw new InvalidOperationException("CosmosDb:AccountEndpoint not configured");
        var databaseName = configuration["CosmosDb:DatabaseName"] ?? throw new InvalidOperationException("CosmosDb:DatabaseName not configured");
        var requestsContainerName = configuration["CosmosDb:RequestsContainerName"] ?? "ProcessRequests";
        var processTypesContainerName = configuration["CosmosDb:ProcessTypesContainerName"] ?? "ProcessTypes";

        var cosmosOptions = new CosmosClientOptions
        {
            SerializerOptions = new CosmosSerializationOptions
            {
                PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
            }
        };

        // Use DefaultAzureCredential for managed identity authentication
        var visualStudioTenantId = configuration["VisualStudioTenantId"] ?? string.Empty;
        var credential = GetCredentials(visualStudioTenantId);
        
        _cosmosClient = new CosmosClient(accountEndpoint, credential, cosmosOptions);
        _requestsContainer = _cosmosClient.GetContainer(databaseName, requestsContainerName);
        _processTypesContainer = _cosmosClient.GetContainer(databaseName, processTypesContainerName);
    }

    public async Task<ProcessRequest> CreateRequestAsync(ProcessRequest request)
    {
        try
        {
            var response = await _requestsContainer.CreateItemAsync(request, new PartitionKey(request.Id));

            _logger.LogInformation("Created request with ID: {RequestId}", request.Id);
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
            var query = new QueryDefinition("SELECT * FROM c WHERE c.isActive = @isActive")
                .WithParameter("@isActive", true);
            var iterator = _processTypesContainer.GetItemQueryIterator<ProcessType>(query);

            var results = new List<ProcessType>();
            while (iterator.HasMoreResults)
            {
                var response = await iterator.ReadNextAsync();
                results.AddRange(response);
            }

            _logger.LogInformation("Retrieved {Count} active process types", results.Count);
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
