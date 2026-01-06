namespace Processor.Agent.Intake.Services;

public interface IValidationService
{
    Task<(bool IsValid, List<string> Errors)> ValidateRequestAsync(RequestData request);
}
