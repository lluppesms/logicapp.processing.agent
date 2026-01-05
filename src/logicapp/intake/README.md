# Intake Processor Logic App

This Azure Logic App (implemented as an Azure Functions project) monitors a Cosmos DB container for new intake requests and processes them by validating the data and formatting email notifications for administrators.

## Overview

The Intake Processor watches a Cosmos DB table for new records. When a new record arrives, it:
1. Validates that all required fields are present and properly formatted
2. Formats an email with the pertinent data
3. Prepares the email to be sent to the application administrator

## Record Data

Each intake request includes the following fields:

- **UniqueRecordId** (required): Unique identifier for this record
- **RequestorName** (required): Name of the person making the request
- **RequestorEmail** (required): Email address of the requestor (validated for proper format)
- **JobTitle** (required): Job title of the requestor
- **ProcessRequested** (required): The process being requested
- **RequiredCompletionDate** (required): Date by which the process must be completed (must be in the future)
- **Comments** (optional): Additional information or notes

## Project Structure

```
IntakeProcessor/
├── Functions/
│   └── IntakeProcessorFunction.cs    # Main Cosmos DB trigger function
├── Models/
│   ├── IntakeRequest.cs              # Data model for intake requests
│   └── ValidationResult.cs           # Validation result model
├── Services/
│   ├── IntakeValidator.cs            # Validates intake requests
│   └── EmailFormatter.cs             # Formats email notifications
├── IntakeProcessor.csproj            # Project file with dependencies
├── Program.cs                        # Application startup and DI configuration
├── host.json                         # Function host configuration
└── local.settings.json               # Local development settings
```

## Configuration

### Local Development

Update `local.settings.json` with your Cosmos DB connection details:

```json
{
  "Values": {
    "CosmosDbConnectionString": "AccountEndpoint=https://your-account.documents.azure.com:443/;AccountKey=your-key",
    "CosmosDbDatabaseName": "IntakeDatabase",
    "CosmosDbContainerName": "IntakeRequests"
  }
}
```

### Azure Deployment

Configure the following application settings in Azure:

- `CosmosDbConnectionString`: Connection string to your Cosmos DB account
- `CosmosDbDatabaseName`: Name of the database containing intake requests
- `CosmosDbContainerName`: Name of the container to monitor

## Validation Rules

The validator ensures:

1. **UniqueRecordId**: Must be present and non-empty
2. **RequestorName**: Must be present and non-empty
3. **RequestorEmail**: Must be present, non-empty, and in valid email format
4. **JobTitle**: Must be present and non-empty
5. **ProcessRequested**: Must be present and non-empty
6. **RequiredCompletionDate**: Must be present and set to a future date

## Email Format

The email notification is formatted as an HTML email with:
- A highlighted Record ID section at the top
- All requestor information clearly labeled
- Professional styling with proper formatting
- HTML-encoded values to prevent injection issues

## Building and Testing

### Build the project

```bash
dotnet build
```

### Run locally

```bash
cd src/logicapp/intake
func start
```

Note: For local development, you'll need:
- Azure Cosmos DB Emulator or a Cosmos DB account
- Azure Storage Emulator or Azure Storage account

## Dependencies

- .NET 10.0
- Microsoft.Azure.Functions.Worker 2.51.0
- Microsoft.Azure.Functions.Worker.Extensions.CosmosDB 4.12.0
- Microsoft.Azure.Cosmos 3.45.0
- Microsoft.ApplicationInsights.WorkerService 2.23.0

## Deployment

This Logic App is designed to be deployed as an Azure Consumption Logic App (Azure Functions). It can be deployed using:

- Azure Functions Core Tools
- Visual Studio/VS Code Azure Functions extension
- Azure DevOps pipelines
- GitHub Actions
- Azure CLI

## Future Enhancements

To complete the email functionality, integrate with an email service provider:

- SendGrid
- Office 365/Microsoft Graph API
- Azure Communication Services
- Custom SMTP service

Add the appropriate NuGet package and update the `IntakeProcessorFunction.cs` to send actual emails instead of just logging.

## License

This project is licensed under the MIT License.
