namespace IntakeProcessor.Models;

public class RequestData
{
    public string RequestorName { get; set; } = string.Empty;
    public string RequestorEmail { get; set; } = string.Empty;
    public string JobTitle { get; set; } = string.Empty;
    public string ProcessRequested { get; set; } = string.Empty;
    public DateTime RequiredCompletionDate { get; set; }
    public string? Comments { get; set; }
}
