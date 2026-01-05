namespace IntakeProcessor.Models;

/// <summary>
/// Represents an intake request from a requestor
/// </summary>
public class IntakeRequest
{
    /// <summary>
    /// Unique identifier for this record
    /// </summary>
    public string UniqueRecordId { get; set; } = string.Empty;

    /// <summary>
    /// Name of the person making the request
    /// </summary>
    public string RequestorName { get; set; } = string.Empty;

    /// <summary>
    /// Email address of the requestor
    /// </summary>
    public string RequestorEmail { get; set; } = string.Empty;

    /// <summary>
    /// Job title of the requestor
    /// </summary>
    public string JobTitle { get; set; } = string.Empty;

    /// <summary>
    /// The process being requested
    /// </summary>
    public string ProcessRequested { get; set; } = string.Empty;

    /// <summary>
    /// Date by which the process must be completed
    /// </summary>
    public DateTime RequiredCompletionDate { get; set; }

    /// <summary>
    /// Optional comments or additional information
    /// </summary>
    public string? Comments { get; set; }

    /// <summary>
    /// Cosmos DB document ID
    /// </summary>
    public string? Id { get; set; }

    /// <summary>
    /// Cosmos DB partition key
    /// </summary>
    public string? PartitionKey { get; set; }
}
