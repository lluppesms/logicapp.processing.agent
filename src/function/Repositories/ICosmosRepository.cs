using IntakeProcessor.Models;

namespace IntakeProcessor.Repositories;

public interface ICosmosRepository
{
    Task<ProcessRequest> CreateRequestAsync(ProcessRequest request);
    Task<IEnumerable<ProcessType>> GetProcessTypesAsync();
}
