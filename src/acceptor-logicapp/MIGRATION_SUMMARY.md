# Acceptor Logic App - Implementation Summary

## Overview

This implementation converts the Acceptor application from an Azure Function to an Azure Logic App Standard workflow. The Logic App provides the same functionality - monitoring a Cosmos DB container for new intake requests and sending email notifications - but uses a declarative, low-code approach.

## Migration Summary

### What Changed

**From: Azure Function (C# .NET 10)**
- Custom C# code for validation and email formatting
- CosmosDB trigger attribute in code
- Service injection for validators and formatters
- Compiled .NET application

**To: Logic App Standard (Workflow)**
- Declarative JSON workflow definition
- Built-in Cosmos DB connector with change feed trigger
- Conditional expressions for validation
- Office 365 connector for email sending
- No custom code required

### Functionality Preserved

✅ **Cosmos DB Trigger**: Uses the same Cosmos DB change feed mechanism
✅ **Validation**: Checks all required fields (id, requestorName, requestorEmail, jobTitle, processRequested, requiredCompletionDate)
✅ **Email Formatting**: Preserves the same HTML email template with professional styling
✅ **Error Handling**: Logs validation errors for invalid documents
✅ **Scalability**: Automatically scales with incoming documents

## File Structure

```
src/acceptor-logicapp/
├── AcceptorWorkflow/
│   └── workflow.json              # Main workflow definition
├── connections.json                # Managed API connections configuration
├── host.json                       # Logic App runtime settings
├── local.settings.json.sample      # Sample configuration for local development
├── .gitignore                      # Git ignore rules
└── README.md                       # Documentation
```

## Infrastructure Changes

### Bicep Modules

**New Module**: `infra/Bicep/modules/logicapp/logicapp.bicep`
- Deploys Logic App Standard (Workflow App)
- Creates App Service Plan (WorkflowStandard tier)
- Creates User Assigned Managed Identity
- Creates Cosmos DB API connection
- Creates Office 365 API connection
- Configures access policies for connections
- Sets all required app settings

**Updated Module**: `infra/Bicep/main.bicep`
- Replaced `functionApp2FlexModule` with `logicAppModule`
- Same resource naming for compatibility
- Updated output variable names

### GitHub Actions Workflows

**New Workflow**: `.github/workflows/template-logicapp-deploy.yml`
- Packages Logic App workflows into zip file
- Deploys to Azure using `az logicapp deployment source config-zip`
- Configures connection runtime URLs
- Compatible with existing deployment patterns

**Updated Workflow**: `.github/workflows/2-build-deploy.yml`
- Replaced acceptor function build/deploy jobs
- Added `deploy-acceptor-logicapp` job
- Uses new Logic App deployment template

## Workflow Logic

### Trigger: When a Document is Created or Modified

```json
{
  "type": "ApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "referenceName": "azurecosmosdb"
      }
    },
    "path": "/v2/cosmosdb/.../changefeed/...",
    "queries": {
      "maxItemsPerInvocation": 100
    }
  },
  "recurrence": {
    "frequency": "Second",
    "interval": 10
  },
  "splitOn": "@triggerBody()"
}
```

**Key Features**:
- Uses `splitOn` to process each document individually
- Polls every 10 seconds
- Processes up to 100 documents per invocation
- Automatically creates workflow instances for each document

### Validation Logic

Implemented as a conditional `If` action that checks:
```
AND(
  NOT(equals(triggerBody()?['id'], null)),
  NOT(equals(triggerBody()?['requestorName'], null)),
  NOT(equals(triggerBody()?['requestorEmail'], null)),
  NOT(equals(triggerBody()?['jobTitle'], null)),
  NOT(equals(triggerBody()?['processRequested'], null)),
  NOT(equals(triggerBody()?['requiredCompletionDate'], null))
)
```

### Email Composition

**Subject**:
```
New Intake Request: {processRequested} - {requestorName}
```

**Body**: HTML template with:
- Professional CSS styling
- Record ID in highlighted section
- All request fields formatted and labeled
- Conditional comments section
- HTML encoding for security

### Email Delivery

Uses Office 365 connector to send email:
```json
{
  "To": "@{appsetting('AdminEmailAddress')}",
  "Subject": "@{outputs('Compose_email_subject')}",
  "Body": "@{outputs('Compose_email_body')}",
  "Importance": "Normal"
}
```

## Configuration Requirements

### App Settings

Required settings configured in Bicep:
- `WORKFLOWS_SUBSCRIPTION_ID` - Azure subscription ID
- `WORKFLOWS_RESOURCE_GROUP_NAME` - Resource group name
- `WORKFLOWS_LOCATION_NAME` - Azure region
- `WORKFLOWS_TENANT_ID` - Azure tenant ID
- `WORKFLOWS_LOGIC_APP_NAME` - Logic App name
- `CosmosDbDatabaseName` - Cosmos DB database name
- `CosmosDbContainerName` - Cosmos DB container name
- `AdminEmailAddress` - Email recipient for notifications

Runtime connection URLs (set during deployment):
- `CosmosDb_connectionRuntimeUrl`
- `office365_connectionRuntimeUrl`

### Managed Connections

Two API connections are created:
1. **azurecosmosdb-{logicAppName}** - Cosmos DB connection
2. **office365-{logicAppName}** - Office 365 Outlook connection

Both use Managed Service Identity for authentication.

## Deployment Process

### Infrastructure Deployment (Bicep)

1. Deploy Logic App Standard resource
2. Create App Service Plan (WorkflowStandard tier)
3. Create User Assigned Managed Identity
4. Create Cosmos DB API connection
5. Create Office 365 API connection
6. Configure access policies
7. Set app settings

### Workflow Deployment (GitHub Actions)

1. Checkout code
2. Create zip package of Logic App files
3. Deploy using `az logicapp deployment source config-zip`
4. Update connection runtime URLs in app settings

## Benefits of Logic App vs. Function

### Advantages

✅ **Visual Designer**: Can edit workflows in VS Code or Azure Portal designer
✅ **No Code Compilation**: Faster iteration and deployment
✅ **Built-in Connectors**: Managed connectors for Cosmos DB and email
✅ **Monitoring**: Rich run history and monitoring in Azure Portal
✅ **Workflow Patterns**: Built-in support for common workflow patterns
✅ **Reduced Maintenance**: No NuGet packages to update
✅ **Lower Code Complexity**: Declarative vs. imperative code

### Considerations

⚠️ **Office 365 Authentication**: May require manual consent for Office 365 connector in Azure Portal
⚠️ **Connection Configuration**: Connection runtime URLs must be configured post-deployment
⚠️ **Limited Debugging**: Cannot step through workflow like code (but has excellent run history)
⚠️ **Connector Limitations**: Limited to what connectors provide (but covers this use case)

## Testing

### Local Testing

```bash
cd src/acceptor-logicapp
# Open in VS Code with Azure Logic Apps extension
# Configure local.settings.json
# Press F5 to run locally (requires Azurite)
```

### Azure Testing

1. Deploy infrastructure using Bicep
2. Deploy workflows using GitHub Actions
3. Verify connections in Azure Portal
4. Add test document to Cosmos DB
5. Check Logic App run history
6. Verify email received

## Next Steps

### Post-Deployment Tasks

1. **Consent Office 365 Connection**: In Azure Portal, open the Office 365 connection and authorize it
2. **Configure Admin Email**: Update `AdminEmailAddress` app setting with actual recipient
3. **Test End-to-End**: Add a test document to Cosmos DB and verify email delivery
4. **Monitor**: Check Logic App run history for any errors

### Optional Enhancements

- Add retry policy for failed email sends
- Add custom tracking properties for better monitoring
- Create separate workflow for handling validation failures
- Add notification for workflow failures
- Implement dead-letter queue for invalid documents

## Migration Checklist

- [x] Create Logic App Standard structure
- [x] Implement Cosmos DB trigger
- [x] Implement validation logic
- [x] Implement email formatting
- [x] Create Bicep deployment module
- [x] Update main Bicep file
- [x] Create GitHub Actions deployment workflow
- [x] Update main deployment workflow
- [x] Create documentation
- [ ] Deploy to Azure (requires manual deployment)
- [ ] Authorize Office 365 connection
- [ ] Test end-to-end functionality
- [ ] Archive/remove old acceptor function code (optional)

## Rollback Plan

If needed to rollback to the Azure Function:

1. Revert changes to `infra/Bicep/main.bicep`
2. Revert changes to `.github/workflows/2-build-deploy.yml`
3. Redeploy infrastructure
4. Deploy acceptor function using existing workflow

The original acceptor function code remains in `src/acceptor-function/` for reference.

## Summary

This migration successfully converts the Acceptor application from an Azure Function to a Logic App Standard workflow while preserving all functionality. The new implementation provides the same capabilities with a more maintainable, visual, and declarative approach that leverages Azure's managed connectors and workflow orchestration capabilities.
