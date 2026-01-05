namespace IntakeProcessor.Models;

/// <summary>
/// Represents the result of validating an intake request
/// </summary>
public class ValidationResult
{
    /// <summary>
    /// Indicates whether the validation passed
    /// </summary>
    public bool IsValid { get; set; }

    /// <summary>
    /// List of validation error messages
    /// </summary>
    public List<string> Errors { get; set; } = new();

    /// <summary>
    /// Creates a successful validation result
    /// </summary>
    public static ValidationResult Success() => new() { IsValid = true };

    /// <summary>
    /// Creates a failed validation result with errors
    /// </summary>
    public static ValidationResult Failure(params string[] errors) => new()
    {
        IsValid = false,
        Errors = errors.ToList()
    };
}
