using System.Text.Json.Serialization;

namespace Processor.Agent.Data.Models;

public class ProcessRequest
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();
    
    [JsonPropertyName("requestorName")]
    public string RequestorName { get; set; } = string.Empty;
    
    [JsonPropertyName("requestorEmail")]
    public string RequestorEmail { get; set; } = string.Empty;
    
    [JsonPropertyName("jobTitle")]
    public string JobTitle { get; set; } = string.Empty;
    
    [JsonPropertyName("processRequested")]
    public string ProcessRequested { get; set; } = string.Empty;
    
    [JsonPropertyName("requiredCompletionDate")]
    public DateTime RequiredCompletionDate { get; set; }
    
    [JsonPropertyName("comments")]
    public string? Comments { get; set; }
    
    [JsonPropertyName("createdDate")]
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = "Pending";
}
