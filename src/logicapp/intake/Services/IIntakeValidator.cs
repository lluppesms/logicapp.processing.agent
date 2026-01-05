namespace Processor.Agent.Acceptor.Services;

/// <summary>
/// Service for validating intake requests
/// </summary>
public interface IIntakeValidator
{
    /// <summary>
    /// Validates an intake request to ensure all required fields are present and valid
    /// </summary>
    /// <param name="request">The intake request to validate</param>
    /// <returns>A validation result indicating success or failure with error messages</returns>
    ValidationResult Validate(ProcessRequest request);
}
