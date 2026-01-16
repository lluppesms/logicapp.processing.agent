namespace Processor.Agent.Acceptor.Functions;

/// <summary>
/// Azure Function triggered by Cosmos DB changes to process intake requests
/// </summary>
public class CosmosAcceptorFunction(ILogger<CosmosAcceptorFunction> logger, IIntakeValidator validator, IEmailFormatter emailFormatter)
{
    private readonly ILogger<CosmosAcceptorFunction> _logger = logger;
    private readonly IIntakeValidator _validator = validator;
    private readonly IEmailFormatter _emailFormatter = emailFormatter;

    /// <summary>
    /// Processes new intake requests from Cosmos DB
    /// </summary>
    /// <param name="input">Array of documents from Cosmos DB change feed</param>
    [Function("IntakeProcessor")]
    public void Run(
        [CosmosDBTrigger(
            databaseName: "%CosmosDbDatabaseName%",
            containerName: "%CosmosDbContainerName%",
            Connection = "CosmosDbConnectionString",
            LeaseContainerName = "leases",
            CreateLeaseContainerIfNotExists = true)]
        IReadOnlyList<ProcessRequest> input)
    {
        if (input == null || input.Count == 0)
        {
            _logger.LogInformation("No new documents to process");
            return;
        }

        _logger.LogInformation("Processing {Count} new intake request(s)", input.Count);

        foreach (var request in input)
        {
            try
            {
                ProcessIntakeRequest(request);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing intake request for {RequestorName}", request.RequestorName);
            }
        }
    }

    /// <summary>
    /// Processes a single intake request
    /// </summary>
    private void ProcessIntakeRequest(ProcessRequest request)
    {
        _logger.LogInformation("Processing intake request from {RequestorName} ({RequestorEmail})", request.RequestorName, request.RequestorEmail);

        // Validate the request
        var validationResult = _validator.Validate(request);

        if (!validationResult.IsValid)
        {
            _logger.LogWarning("Intake request validation failed for {RequestorName}. Errors: {Errors}", request.RequestorName, string.Join(", ", validationResult.Errors));

            // In a production scenario, you might want to:
            // - Store the validation errors
            // - Send a notification about invalid data
            // - Move the document to a dead-letter collection
            return;
        }

        _logger.LogInformation("Intake request validation succeeded for {RequestorName}", request.RequestorName);

        // Format the email
        var emailSubject = _emailFormatter.GetEmailSubject(request);
        var emailBody = _emailFormatter.FormatEmailBody(request);

        // Log the email details (in production, this would send via SendGrid, Office 365, etc.)
        _logger.LogInformation("Email prepared for administrator");
        _logger.LogInformation("Subject: {Subject}", emailSubject);
        _logger.LogInformation("Email body generated with {Length} characters", emailBody.Length);

        // TODO: In production, integrate with email service
        // Example using SendGrid or Office 365 connectors:
        // await _emailService.SendEmailAsync(
        //     to: "admin@example.com",
        //     subject: emailSubject,
        //     htmlBody: emailBody
        // );

        _logger.LogInformation("Successfully processed intake request for {RequestorName}", request.RequestorName);
    }
}
