# Intake Processor Azure Function

This is a .NET 10 Azure Function application that accepts and processes intake requests via HTTP.

## Overview

The Intake Processor accepts JSON data from users, validates it, and stores successful records in Azure Cosmos DB.

## Input Data Format

The HTTP endpoint accepts POST requests with JSON data containing the following fields:

```json
{
  "requestorName": "John Doe",
  "requestorEmail": "john.doe@example.com",
  "jobTitle": "Software Engineer",
  "processRequested": "Document Processing",
  "requiredCompletionDate": "2026-02-15T00:00:00Z",
  "comments": "Optional comments field"
}
```

### Required Fields

- **requestorName**: Name of the person making the request
- **requestorEmail**: Valid email address of the requestor
- **jobTitle**: Job title of the requestor
- **processRequested**: Type of process being requested (must be a valid process type from the database)
- **requiredCompletionDate**: Date when the process should be completed (cannot be in the past)

### Optional Fields

- **comments**: Additional comments or notes

## Validation

The function performs the following validations:

1. **Field Presence**: Ensures all required fields are present and not empty
2. **Email Format**: Validates the email address format using regex
3. **Process Type**: Validates that the requested process exists in the ProcessTypes table in Cosmos DB
4. **Date Validation**: Ensures the required completion date is not in the past

## Process Type Caching

To optimize performance, the function caches valid process types from Cosmos DB for 30 minutes. This reduces database calls and improves response times.

## Configuration

The function requires the following configuration values (in `local.settings.json` for local development or App Settings for Azure):

```json
{
  "CosmosDb:ConnectionString": "Your Cosmos DB connection string",
  "CosmosDb:DatabaseName": "Database name",
  "CosmosDb:RequestsContainerName": "ProcessRequests",
  "CosmosDb:ProcessTypesContainerName": "ProcessTypes"
}
```

## Cosmos DB Setup

The function expects two containers in Cosmos DB:

1. **ProcessRequests**: Stores submitted requests
   - Partition Key: `/id`
   
2. **ProcessTypes**: Stores valid process types
   - Partition Key: `/id`
   - Sample document:
     ```json
     {
       "id": "1",
       "name": "Document Processing",
       "description": "Process documents",
       "isActive": true
     }
     ```

## API Endpoint

### Submit Request

- **URL**: `/api/requests`
- **Method**: `POST`
- **Content-Type**: `application/json`
- **Authorization**: Function key required

#### Success Response

- **Code**: 201 Created
- **Content**:
  ```json
  {
    "success": true,
    "requestId": "generated-guid",
    "message": "Request submitted successfully"
  }
  ```

#### Error Response

- **Code**: 400 Bad Request
- **Content**:
  ```json
  {
    "success": false,
    "errors": [
      "List of validation errors"
    ]
  }
  ```

## Local Development

1. Install the Azure Cosmos DB Emulator or update `local.settings.json` with your Cosmos DB credentials
2. Run the function:
   ```bash
   func start
   ```

## Deployment

This function is designed to be deployed as an Azure Flex Function. The infrastructure is defined in the Bicep files located in the `infra` folder.

## Project Structure

```
IntakeProcessor/
├── Functions/
│   └── IntakeFunction.cs       # HTTP-triggered function
├── Models/
│   ├── RequestData.cs          # Input model
│   ├── ProcessRequest.cs       # Cosmos DB entity
│   └── ProcessType.cs          # Process type entity
├── Repositories/
│   ├── ICosmosRepository.cs    # Repository interface
│   └── CosmosRepository.cs     # Cosmos DB implementation
├── Services/
│   ├── IValidationService.cs   # Validation interface
│   └── ValidationService.cs    # Validation with caching
└── Program.cs                  # DI configuration
```

## Dependencies

- .NET 10
- Microsoft.Azure.Functions.Worker (2.51.0)
- Microsoft.Azure.Cosmos (3.48.0)
- Newtonsoft.Json (13.0.3)
