# Acceptor Logic App

This Azure Logic App Standard monitors a Cosmos DB container for new intake requests and sends email notifications when new records are created.

## Overview

The Acceptor Logic App watches a Cosmos DB container for new records. When a new record arrives, it:
1. Validates that all required fields are present
2. Formats an email with the pertinent data
3. Sends the email to the application administrator via Office 365 connector

## Architecture

This is an Azure Logic App Standard (Stateful workflow) that uses:
- **Cosmos DB Trigger**: Monitors changes to the Cosmos DB container using the change feed
- **Office 365 Connector**: Sends email notifications

## Workflow Structure

```
AcceptorWorkflow/
└── workflow.json          # Main workflow definition
```

## Configuration

### Local Development

Create a `local.settings.json` file based on `local.settings.json.sample`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "WORKFLOWS_TENANT_ID": "your-tenant-id",
    "WORKFLOWS_SUBSCRIPTION_ID": "your-subscription-id",
    "WORKFLOWS_RESOURCE_GROUP_NAME": "your-resource-group",
    "WORKFLOWS_LOCATION_NAME": "eastus",
    "CosmosDbDatabaseName": "lapagent-data-dev",
    "CosmosDbContainerName": "ProcessRequests",
    "CosmosDb_connectionRuntimeUrl": "https://your-connection-url",
    "office365_connectionRuntimeUrl": "https://your-connection-url",
    "AdminEmailAddress": "admin@example.com"
  }
}
```

### Azure Deployment

Configure the following application settings in Azure:
- `WORKFLOWS_SUBSCRIPTION_ID`: Azure subscription ID
- `WORKFLOWS_RESOURCE_GROUP_NAME`: Resource group name
- `WORKFLOWS_LOCATION_NAME`: Azure region (e.g., eastus)
- `CosmosDbDatabaseName`: Name of the database containing intake requests
- `CosmosDbContainerName`: Name of the container to monitor
- `CosmosDb_connectionRuntimeUrl`: Runtime URL for the Cosmos DB connection
- `office365_connectionRuntimeUrl`: Runtime URL for the Office 365 connection
- `AdminEmailAddress`: Email address to send notifications to

## Managed Connections

This Logic App uses two managed API connections:

1. **Azure Cosmos DB** (`azurecosmosdb`)
   - Used to monitor the change feed for new documents
   - Authenticated using Managed Service Identity

2. **Office 365 Outlook** (`office365`)
   - Used to send email notifications
   - Authenticated using Managed Service Identity

These connections are defined in `connections.json` and must be deployed as Azure resources before the Logic App can run.

## Validation Rules

The workflow validates that the following fields are present and non-null:
1. **Id**: Unique identifier for the record
2. **RequestorName**: Name of the person making the request
3. **RequestorEmail**: Email address of the requestor
4. **JobTitle**: Job title of the requestor
5. **ProcessRequested**: The process being requested
6. **RequiredCompletionDate**: Date by which the process must be completed

If any required field is missing, the workflow logs a validation error instead of sending an email.

## Email Format

The email notification is formatted as an HTML email with:
- A highlighted Record ID section at the top
- All requestor information clearly labeled
- Professional styling with proper formatting
- Optional comments section (shown only when comments exist)

## Building and Deploying

### Local Development

```bash
# Install Azure Logic Apps extension for VS Code
# Open the folder in VS Code
# Press F5 to run locally
```

### Azure Deployment

This Logic App is deployed using Bicep infrastructure as code. The deployment:
1. Creates the Logic App Standard resource
2. Creates and configures managed API connections for Cosmos DB and Office 365
3. Configures application settings
4. Deploys the workflow

See `infra/Bicep/modules/logicapp/` for deployment templates.

## Dependencies

- Azure Logic Apps Standard runtime
- Azure Cosmos DB (with change feed enabled)
- Office 365 account for sending emails
- Managed Identity for authentication

## Migration from Azure Function

This Logic App replaces the previous `acceptor-function` Azure Function implementation. The key differences are:

- **No custom code**: All logic is declarative in the workflow definition
- **Built-in connectors**: Uses managed connectors for Cosmos DB and email
- **Visual designer**: Can be edited using the Logic Apps Designer in VS Code or Azure Portal
- **Same functionality**: Provides the same validation and email formatting capabilities

## License

This project is licensed under the MIT License.
