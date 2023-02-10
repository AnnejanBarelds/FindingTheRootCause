using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using OrderProcessor;
using Refit;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

[assembly: FunctionsStartup(typeof(Startup))]

namespace OrderProcessor
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddRefitClient<IInventoryApi>()
                .ConfigureHttpClient(httpClient =>
                {
                    var config = builder.GetContext().Configuration;
                    
                    httpClient.BaseAddress = new Uri(Environment.GetEnvironmentVariable("InventoryApi__Endpoint"));
                    httpClient.DefaultRequestHeaders.Add("x-functions-key", Environment.GetEnvironmentVariable("InventoryApi__ApiKey"));
                });
        }
    }
}
