using Processor.Agent.Data.Models;
using System.Text;

namespace IntakeProcessor.Services;

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

/// <summary>
/// Implementation of the email formatter
/// </summary>
public class EmailFormatter : IEmailFormatter
{
    /// <summary>
    /// Formats an intake request into an HTML email body
    /// </summary>
    public string FormatEmailBody(ProcessRequest request)
    {
        var sb = new StringBuilder();
        
        sb.AppendLine("<!DOCTYPE html>");
        sb.AppendLine("<html>");
        sb.AppendLine("<head>");
        sb.AppendLine("    <style>");
        sb.AppendLine("        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }");
        sb.AppendLine("        .container { max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }");
        sb.AppendLine("        h2 { color: #0066cc; border-bottom: 2px solid #0066cc; padding-bottom: 10px; }");
        sb.AppendLine("        .field { margin: 15px 0; }");
        sb.AppendLine("        .label { font-weight: bold; color: #555; }");
        sb.AppendLine("        .value { margin-left: 10px; }");
        sb.AppendLine("        .record-id { background-color: #f0f8ff; padding: 10px; border-left: 4px solid #0066cc; margin: 20px 0; }");
        sb.AppendLine("        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #888; }");
        sb.AppendLine("    </style>");
        sb.AppendLine("</head>");
        sb.AppendLine("<body>");
        sb.AppendLine("    <div class='container'>");
        sb.AppendLine("        <h2>New Intake Request</h2>");
        sb.AppendLine("        <p>A new intake request has been received and requires your attention.</p>");
        
        sb.AppendLine("        <div class='record-id'>");
        sb.AppendLine($"            <span class='label'>Record ID:</span>");
        sb.AppendLine($"            <span class='value'>{System.Net.WebUtility.HtmlEncode(request.Id)}</span>");
        sb.AppendLine("        </div>");
        
        sb.AppendLine("        <div class='field'>");
        sb.AppendLine($"            <span class='label'>Requestor Name:</span>");
        sb.AppendLine($"            <span class='value'>{System.Net.WebUtility.HtmlEncode(request.RequestorName)}</span>");
        sb.AppendLine("        </div>");
        
        sb.AppendLine("        <div class='field'>");
        sb.AppendLine($"            <span class='label'>Requestor Email:</span>");
        sb.AppendLine($"            <span class='value'><a href='mailto:{System.Net.WebUtility.HtmlEncode(request.RequestorEmail)}'>{System.Net.WebUtility.HtmlEncode(request.RequestorEmail)}</a></span>");
        sb.AppendLine("        </div>");
        
        sb.AppendLine("        <div class='field'>");
        sb.AppendLine($"            <span class='label'>Job Title:</span>");
        sb.AppendLine($"            <span class='value'>{System.Net.WebUtility.HtmlEncode(request.JobTitle)}</span>");
        sb.AppendLine("        </div>");
        
        sb.AppendLine("        <div class='field'>");
        sb.AppendLine($"            <span class='label'>Process Requested:</span>");
        sb.AppendLine($"            <span class='value'>{System.Net.WebUtility.HtmlEncode(request.ProcessRequested)}</span>");
        sb.AppendLine("        </div>");
        
        sb.AppendLine("        <div class='field'>");
        sb.AppendLine($"            <span class='label'>Required Completion Date:</span>");
        sb.AppendLine($"            <span class='value'>{request.RequiredCompletionDate:yyyy-MM-dd}</span>");
        sb.AppendLine("        </div>");
        
        if (!string.IsNullOrWhiteSpace(request.Comments))
        {
            sb.AppendLine("        <div class='field'>");
            sb.AppendLine($"            <span class='label'>Comments:</span>");
            sb.AppendLine($"            <div class='value' style='margin-top: 5px; padding: 10px; background-color: #f5f5f5; border-radius: 3px;'>");
            sb.AppendLine($"                {System.Net.WebUtility.HtmlEncode(request.Comments)}");
            sb.AppendLine("            </div>");
            sb.AppendLine("        </div>");
        }
        
        sb.AppendLine("        <div class='footer'>");
        sb.AppendLine("            <p>This is an automated notification from the Intake Processor system.</p>");
        sb.AppendLine("        </div>");
        sb.AppendLine("    </div>");
        sb.AppendLine("</body>");
        sb.AppendLine("</html>");
        
        return sb.ToString();
    }

    /// <summary>
    /// Gets the email subject for an intake request
    /// </summary>
    public string GetEmailSubject(ProcessRequest request)
    {
        return $"New Intake Request: {request.ProcessRequested} - {request.RequestorName}";
    }
}
