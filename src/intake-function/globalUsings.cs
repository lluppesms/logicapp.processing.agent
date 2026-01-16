global using Processor.Agent.Intake.Repositories;
global using Processor.Agent.Intake.Services;
global using Processor.Agent.Data.Models;

global using Azure.Identity;
global using Microsoft.Azure.Cosmos;
global using Microsoft.Azure.Functions.Worker;
global using Microsoft.Azure.Functions.Worker.Http;
global using Microsoft.Azure.Functions.Worker.Builder;

global using Microsoft.Extensions.Configuration;
global using Microsoft.Extensions.Caching.Memory;
global using Microsoft.Extensions.DependencyInjection;
global using Microsoft.Extensions.Hosting;
global using Microsoft.Extensions.Logging;

global using System.Net.Mail;
global using System.Net;
global using System.Text.Json;
