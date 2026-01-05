using Processor.Agent.Data.Models;

namespace Processor.Agent.Intake.Repositories;

public interface ICosmosRepository
{
    Task<ProcessRequest> CreateRequestAsync(ProcessRequest request);
    Task<IEnumerable<ProcessType>> GetProcessTypesAsync();
}
