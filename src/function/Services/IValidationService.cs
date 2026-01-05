using IntakeProcessor.Models;

namespace IntakeProcessor.Services;

public interface IValidationService
{
    Task<(bool IsValid, List<string> Errors)> ValidateRequestAsync(RequestData request);
}
