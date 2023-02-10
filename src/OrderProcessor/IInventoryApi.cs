using Refit;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace OrderProcessor
{
    public interface IInventoryApi
    {
        [Post("/api/reservations")]
        Task<IApiResponse> ReserveProducts([Body]IEnumerable<string> skus);
    }
}
