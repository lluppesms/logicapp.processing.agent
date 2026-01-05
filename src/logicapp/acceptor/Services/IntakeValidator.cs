namespace Processor.Agent.Acceptor.Services;

/// <summary>
/// Implementation of the intake request validator
/// </summary>
public class IntakeValidator : IIntakeValidator
{
    /// <summary>
    /// Validates an intake request to ensure all required fields are present and valid
    /// </summary>
    public ValidationResult Validate(ProcessRequest request)
    {
        var errors = new List<string>();

        // Validate unique record ID
        if (string.IsNullOrWhiteSpace(request.Id))
        {
            errors.Add("Unique Record ID is required");
        }

        // Validate required fields
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
            errors.Add("Requestor Email is not in a valid format");
        }

        if (string.IsNullOrWhiteSpace(request.JobTitle))
        {
            errors.Add("Job Title is required");
        }

        if (string.IsNullOrWhiteSpace(request.ProcessRequested))
        {
            errors.Add("Process Requested is required");
        }

        if (request.RequiredCompletionDate == default)
        {
            errors.Add("Required Completion Date is required");
        }
        else if (request.RequiredCompletionDate < DateTime.UtcNow.Date)
        {
            errors.Add("Required Completion Date must be in the future");
        }

        return errors.Any()
            ? ValidationResult.Failure(errors.ToArray())
            : ValidationResult.Success();
    }

    /// <summary>
    /// Simple email validation
    /// </summary>
    private static bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }
}
