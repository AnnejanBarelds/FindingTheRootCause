using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using OrderFulfillmentProcessor;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

[assembly: FunctionsStartup(typeof(Startup))]

namespace OrderFulfillmentProcessor
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            
        }
    }
}
