
var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

// Register application services
builder.Services.AddSingleton<IIntakeValidator, IntakeValidator>();
builder.Services.AddSingleton<IEmailFormatter, EmailFormatter>();

builder.Build().Run();
