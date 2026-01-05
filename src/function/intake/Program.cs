
var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

builder.Services.AddMemoryCache();

builder.Services.AddSingleton<ICosmosRepository, CosmosRepository>();
builder.Services.AddSingleton<IValidationService, ValidationService>();

builder.Build().Run();
