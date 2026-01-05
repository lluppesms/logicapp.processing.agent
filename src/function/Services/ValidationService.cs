using IntakeProcessor.Models;
using IntakeProcessor.Repositories;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using System.Text.RegularExpressions;

namespace IntakeProcessor.Services;

public class ValidationService : IValidationService
{
    private readonly ICosmosRepository _repository;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ValidationService> _logger;
    private const string ProcessTypesCacheKey = "ProcessTypes";
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(30);

    public ValidationService(
        ICosmosRepository repository,
        IMemoryCache cache,
        ILogger<ValidationService> logger)
    {
        _repository = repository;
        _cache = cache;
        _logger = logger;
    }

    public async Task<(bool IsValid, List<string> Errors)> ValidateRequestAsync(RequestData request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.RequestorName))
        {
            errors.Add("Requestor Name is required");
        }

        if (string.IsNullOrWhiteSpace(request.RequestorEmail))
        {
            errors.Add("Requestor Email is required");
        }
        else if (!IsValidEmail(request.RequestorEmail))
        {
            errors.Add("Requestor Email is not valid");
        }

        if (string.IsNullOrWhiteSpace(request.JobTitle))
        {
            errors.Add("Job Title is required");
        }

        if (string.IsNullOrWhiteSpace(request.ProcessRequested))
        {
            errors.Add("Process Requested is required");
        }
        else
        {
            var isValidProcess = await IsValidProcessTypeAsync(request.ProcessRequested);
            if (!isValidProcess)
            {
                errors.Add($"Process Requested '{request.ProcessRequested}' is not a valid process type");
            }
        }

        if (request.RequiredCompletionDate == default)
        {
            errors.Add("Required Completion Date is required");
        }
        else if (request.RequiredCompletionDate < DateTime.UtcNow.Date)
        {
            errors.Add("Required Completion Date cannot be in the past");
        }

        var isValid = errors.Count == 0;
        if (!isValid)
        {
            _logger.LogWarning("Validation failed with {ErrorCount} errors", errors.Count);
        }

        return (isValid, errors);
    }

    private async Task<bool> IsValidProcessTypeAsync(string processName)
    {
        var processTypes = await GetCachedProcessTypesAsync();
        return processTypes.Any(pt => 
            pt.Name.Equals(processName, StringComparison.OrdinalIgnoreCase) && pt.IsActive);
    }

    private async Task<IEnumerable<ProcessType>> GetCachedProcessTypesAsync()
    {
        if (!_cache.TryGetValue(ProcessTypesCacheKey, out IEnumerable<ProcessType>? processTypes))
        {
            _logger.LogInformation("Process types not in cache, fetching from database");
            processTypes = await _repository.GetProcessTypesAsync();
            
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(CacheDuration);
            
            _cache.Set(ProcessTypesCacheKey, processTypes, cacheOptions);
            _logger.LogInformation("Cached {Count} process types for {Duration} minutes", 
                processTypes.Count(), CacheDuration.TotalMinutes);
        }
        else
        {
            _logger.LogDebug("Retrieved {Count} process types from cache", processTypes?.Count() ?? 0);
        }

        return processTypes ?? Enumerable.Empty<ProcessType>();
    }

    private static bool IsValidEmail(string email)
    {
        var emailPattern = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
        return Regex.IsMatch(email, emailPattern);
    }
}
