using IntakeProcessor.Models;
using IntakeProcessor.Repositories;
using IntakeProcessor.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Text.Json;

namespace IntakeProcessor.Functions;

public class IntakeFunction
{
    private readonly ILogger<IntakeFunction> _logger;
    private readonly IValidationService _validationService;
    private readonly ICosmosRepository _repository;

    public IntakeFunction(
        ILogger<IntakeFunction> logger,
        IValidationService validationService,
        ICosmosRepository repository)
    {
        _logger = logger;
        _validationService = validationService;
        _repository = repository;
    }

    [Function("SubmitRequest")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "requests")] HttpRequestData req)
    {
        _logger.LogInformation("Processing request submission");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            
            if (string.IsNullOrWhiteSpace(requestBody))
            {
                return await CreateErrorResponse(req, HttpStatusCode.BadRequest, "Request body is empty");
            }

            RequestData? requestData;
            try
            {
                requestData = JsonSerializer.Deserialize<RequestData>(requestBody, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(ex, "Invalid JSON in request body");
                return await CreateErrorResponse(req, HttpStatusCode.BadRequest, "Invalid JSON format");
            }

            if (requestData == null)
            {
                return await CreateErrorResponse(req, HttpStatusCode.BadRequest, "Failed to parse request data");
            }

            var (isValid, errors) = await _validationService.ValidateRequestAsync(requestData);
            
            if (!isValid)
            {
                _logger.LogWarning("Request validation failed: {Errors}", string.Join(", ", errors));
                var errorResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await errorResponse.WriteAsJsonAsync(new { 
                    success = false, 
                    errors = errors 
                });
                return errorResponse;
            }

            var processRequest = new ProcessRequest
            {
                RequestorName = requestData.RequestorName,
                RequestorEmail = requestData.RequestorEmail,
                JobTitle = requestData.JobTitle,
                ProcessRequested = requestData.ProcessRequested,
                RequiredCompletionDate = requestData.RequiredCompletionDate,
                Comments = requestData.Comments
            };

            var createdRequest = await _repository.CreateRequestAsync(processRequest);
            
            _logger.LogInformation("Successfully created request with ID: {RequestId}", createdRequest.Id);

            var successResponse = req.CreateResponse(HttpStatusCode.Created);
            await successResponse.WriteAsJsonAsync(new 
            { 
                success = true, 
                requestId = createdRequest.Id,
                message = "Request submitted successfully"
            });
            
            return successResponse;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing request submission");
            return await CreateErrorResponse(req, HttpStatusCode.InternalServerError, 
                "An error occurred while processing your request");
        }
    }

    private static async Task<HttpResponseData> CreateErrorResponse(
        HttpRequestData req, 
        HttpStatusCode statusCode, 
        string message)
    {
        var response = req.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(new { success = false, error = message });
        return response;
    }
}
