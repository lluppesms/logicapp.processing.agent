# Azure Function Intake Processor - Implementation Summary

## Overview
Successfully created a .NET 10 Azure Function application that accepts HTTP requests with JSON data, validates the input, and stores successful records in Azure Cosmos DB.

## Project Location
`/src/function/`

## Architecture

### Components

1. **HTTP Function** (`Functions/IntakeFunction.cs`)
   - POST endpoint: `/api/requests`
   - Accepts JSON request data
   - Returns validation errors or success response
   - Function-level authorization

2. **Models** (`Models/`)
   - `RequestData.cs`: Input DTO for HTTP requests
   - `ProcessRequest.cs`: Cosmos DB entity with metadata
   - `ProcessType.cs`: Reference data for valid process types

3. **Repository Layer** (`Repositories/`)
   - `ICosmosRepository.cs`: Interface for data access
   - `CosmosRepository.cs`: Cosmos DB implementation
   - Handles CRUD operations for requests and process types

4. **Service Layer** (`Services/`)
   - `IValidationService.cs`: Validation interface
   - `ValidationService.cs`: Input validation with caching
   - 30-minute cache for process types
   - Email validation using MailAddress
   - Date validation (no past dates)

## Input Data Format

```json
{
  "requestorName": "John Doe",
  "requestorEmail": "john.doe@example.com",
  "jobTitle": "Software Engineer",
  "processRequested": "Document Processing",
  "requiredCompletionDate": "2026-02-15T00:00:00Z",
  "comments": "Optional comments"
}
```

## Validation Rules

1. **Required Fields**: RequestorName, RequestorEmail, JobTitle, ProcessRequested, RequiredCompletionDate
2. **Email Format**: Uses .NET MailAddress for robust validation
3. **Process Type**: Must exist in ProcessTypes container with isActive=true
4. **Date**: Cannot be in the past

## Response Formats

### Success (201 Created)
```json
{
  "success": true,
  "requestId": "guid-here",
  "message": "Request submitted successfully"
}
```

### Validation Error (400 Bad Request)
```json
{
  "success": false,
  "errors": [
    "Requestor Email is not valid",
    "Process Requested 'InvalidProcess' is not a valid process type"
  ]
}
```

### Server Error (500)
```json
{
  "success": false,
  "error": "An error occurred while processing your request"
}
```

## Cosmos DB Setup

### Database
- Name: `MathStormData-{environmentCode}`

### Containers

#### ProcessRequests
- Partition Key: `/id`
- Stores submitted requests
- Documents include: id, requestorName, requestorEmail, jobTitle, processRequested, requiredCompletionDate, comments, createdDate, status

#### ProcessTypes
- Partition Key: `/id`
- Stores valid process types
- Documents include: id, name, description, isActive

### Sample ProcessType Document
```json
{
  "id": "1",
  "name": "Document Processing",
  "description": "Process and analyze documents",
  "isActive": true
}
```

## Configuration

### Local Development
1. Copy `local.settings.json.sample` to `local.settings.json`
2. Update Cosmos DB connection string
3. Run with `func start`

### Azure Deployment
Configure App Settings:
- `CosmosDb:ConnectionString`
- `CosmosDb:DatabaseName`
- `CosmosDb:RequestsContainerName`
- `CosmosDb:ProcessTypesContainerName`

## Infrastructure Changes

Updated `infra/Bicep/main.bicep` to include:
- ProcessRequests container
- ProcessTypes container

Both containers use `/id` as partition key and are created when Cosmos DB is deployed.

## Dependencies

- Microsoft.Azure.Functions.Worker (2.51.0)
- Microsoft.Azure.Cosmos (3.48.0)
- Newtonsoft.Json (13.0.3)
- Microsoft.Extensions.Caching.Memory (in-memory cache)

## Performance Optimizations

1. **Process Type Caching**: Process types are cached for 30 minutes to reduce database calls
2. **Singleton Services**: Repository and validation service registered as singletons
3. **Parameterized Queries**: Cosmos queries use parameters for better performance

## Security Features

1. **Function-level authorization** required for API access
2. **Input validation** prevents invalid data from being stored
3. **Parameterized queries** prevent injection attacks
4. **No secrets in code** - all credentials in configuration
5. **CodeQL scan passed** with 0 vulnerabilities

## Code Quality

- ✅ Clean architecture with separation of concerns
- ✅ Dependency injection for testability
- ✅ Comprehensive logging throughout
- ✅ Proper error handling and user feedback
- ✅ Code review feedback addressed
- ✅ Security scan passed

## Testing the Function

### Using curl
```bash
curl -X POST http://localhost:7071/api/requests \
  -H "Content-Type: application/json" \
  -d '{
    "requestorName": "John Doe",
    "requestorEmail": "john.doe@example.com",
    "jobTitle": "Software Engineer",
    "processRequested": "Document Processing",
    "requiredCompletionDate": "2026-02-15T00:00:00Z",
    "comments": "Test request"
  }'
```

### Using Postman
1. Method: POST
2. URL: `http://localhost:7071/api/requests`
3. Headers: `Content-Type: application/json`
4. Body: Raw JSON (see format above)

## Next Steps

1. **Deploy Infrastructure**: Run Bicep deployment to create Cosmos containers
2. **Seed ProcessTypes**: Add valid process types to ProcessTypes container
3. **Deploy Function**: Deploy to Azure Flex Function
4. **Configure App Settings**: Set Cosmos DB connection string
5. **Test**: Verify functionality in Azure

## Deployment Compatibility

This function is designed to work with:
- Azure Flex Function (as specified in requirements)
- .NET 10 runtime
- Existing Bicep infrastructure in the repository
- Existing CI/CD pipelines (GitHub Actions workflows already present)

## Files Created

1. `/src/function/IntakeProcessor.csproj` - Project file
2. `/src/function/Program.cs` - Dependency injection setup
3. `/src/function/Functions/IntakeFunction.cs` - HTTP endpoint
4. `/src/function/Models/RequestData.cs` - Input model
5. `/src/function/Models/ProcessRequest.cs` - Database entity
6. `/src/function/Models/ProcessType.cs` - Reference data model
7. `/src/function/Repositories/ICosmosRepository.cs` - Repository interface
8. `/src/function/Repositories/CosmosRepository.cs` - Database access
9. `/src/function/Services/IValidationService.cs` - Validation interface
10. `/src/function/Services/ValidationService.cs` - Validation logic
11. `/src/function/host.json` - Function host configuration
12. `/src/function/local.settings.json.sample` - Sample configuration
13. `/src/function/README.md` - Function documentation

## Infrastructure Files Updated

1. `/infra/Bicep/main.bicep` - Added ProcessRequests and ProcessTypes containers
