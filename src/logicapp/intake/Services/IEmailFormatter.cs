namespace Processor.Agent.Acceptor.Services;

/// <summary>
/// Service for formatting email content
/// </summary>
public interface IEmailFormatter
{
    /// <summary>
    /// Formats an intake request into an email body
    /// </summary>
    /// <param name="request">The intake request to format</param>
    /// <returns>Formatted email body as HTML</returns>
    string FormatEmailBody(ProcessRequest request);

    /// <summary>
    /// Gets the email subject for an intake request
    /// </summary>
    /// <param name="request">The intake request</param>
    /// <returns>Email subject line</returns>
    string GetEmailSubject(ProcessRequest request);
}
