namespace Processor.Agent.Intake.Services;

public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds services to the service collection.
    /// </summary>
    public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration configuration)
    {
        // Configure Cosmos DB based on available settings
        var cosmosClientOptions = new CosmosClientOptions
        {
            MaxRetryAttemptsOnRateLimitedRequests = 3,
            MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(30)
        };

        var cosmosEndpoint = configuration["CosmosDb:Endpoint"];
        var connectionString = configuration["CosmosDb:ConnectionString"];
        if (string.IsNullOrEmpty(cosmosEndpoint) && string.IsNullOrEmpty(connectionString))
        {
            throw new ArgumentException("CosmosDbService.Init: Either Endpoint or ConnectionString must be provided in configuration.");
        }

        if (!string.IsNullOrEmpty(cosmosEndpoint))
        {
            // Use Managed Identity authentication
            Console.WriteLine("CosmosDbService.Init: Using Managed Identity authentication.");
            services.AddSingleton<CosmosClient>(provider =>
            {
                var creds = new DefaultAzureCredential();
                var visualStudioTenantId = configuration["VisualStudioTenantId"];
                if (!string.IsNullOrEmpty(visualStudioTenantId))
                {
                    creds = new DefaultAzureCredential(new DefaultAzureCredentialOptions
                    {
                        ExcludeEnvironmentCredential = true,
                        ExcludeManagedIdentityCredential = true,
                        TenantId = visualStudioTenantId
                    });
                }
                return new CosmosClient(cosmosEndpoint, creds, cosmosClientOptions);
            });
            services.AddSingleton<ICosmosRepository, CosmosRepository>();
        }
        else if (!string.IsNullOrEmpty(connectionString))
        {
            // Use connection string authentication
            Console.WriteLine("CosmosDbService.Init: Using Connection String authentication.");
            services.AddSingleton<CosmosClient>(_ => new CosmosClient(connectionString, cosmosClientOptions));
            services.AddSingleton<ICosmosRepository, CosmosRepository>();
        }
        //else
        //{
        //    // Use mock service when no Cosmos configuration is found
        //    services.AddSingleton<ICosmosRepository, MockCosmosDbService>();
        //}

        services.AddSingleton<IValidationService, ValidationService>();

        return services;
    }
}
