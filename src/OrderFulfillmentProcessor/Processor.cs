using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using DTO;
using Microsoft.Azure.Documents;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace OrderFulfillmentProcessor
{
    public class Processor
    {
        [FunctionName("OrderFulfillmentProcessor")]
        public void Run([CosmosDBTrigger("%EventsDB%", "%OrderEventsContainer%", Connection = "CosmosDbConnection", LeaseContainerName = "%LeaseContainer%")]IReadOnlyList<OrderEvent> input,
            ILogger log)
        {
            if (input != null && input.Count > 0)
            {
                log.LogInformation("Events processed: {count} " + input.Count);

                foreach (var @event in input)
                {
                    @event.Trace();

                    log.LogInformation("Event processed: {id} " + @event.id);
                    log.LogInformation("Order processed: {OrderId} " + @event.OrderId);
                }
            }
        }
    }
}
