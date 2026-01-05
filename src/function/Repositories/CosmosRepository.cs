using IntakeProcessor.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace IntakeProcessor.Repositories;

public class CosmosRepository : ICosmosRepository
{
    private readonly CosmosClient _cosmosClient;
    private readonly Container _requestsContainer;
    private readonly Container _processTypesContainer;
    private readonly ILogger<CosmosRepository> _logger;

    public CosmosRepository(
        IConfiguration configuration,
        ILogger<CosmosRepository> logger)
    {
        _logger = logger;
        
        var connectionString = configuration["CosmosDb:ConnectionString"] 
            ?? throw new InvalidOperationException("CosmosDb:ConnectionString not configured");
        var databaseName = configuration["CosmosDb:DatabaseName"] 
            ?? throw new InvalidOperationException("CosmosDb:DatabaseName not configured");
        var requestsContainerName = configuration["CosmosDb:RequestsContainerName"] ?? "ProcessRequests";
        var processTypesContainerName = configuration["CosmosDb:ProcessTypesContainerName"] ?? "ProcessTypes";

        _cosmosClient = new CosmosClient(connectionString);
        _requestsContainer = _cosmosClient.GetContainer(databaseName, requestsContainerName);
        _processTypesContainer = _cosmosClient.GetContainer(databaseName, processTypesContainerName);
    }

    public async Task<ProcessRequest> CreateRequestAsync(ProcessRequest request)
    {
        try
        {
            var response = await _requestsContainer.CreateItemAsync(
                request,
                new PartitionKey(request.Id));
            
            _logger.LogInformation("Created request with ID: {RequestId}", request.Id);
            return response.Resource;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating request in Cosmos DB");
            throw;
        }
    }

    public async Task<IEnumerable<ProcessType>> GetProcessTypesAsync()
    {
        try
        {
            var query = new QueryDefinition("SELECT * FROM c WHERE c.isActive = true");
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
            _logger.LogError(ex, "Error retrieving process types from Cosmos DB");
            throw;
        }
    }
}
