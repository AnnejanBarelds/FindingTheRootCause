using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace CustomerLoyaltyProcessor
{
    public class Processor
    {
        private readonly ILogger<Processor> _logger;

        public Processor(ILogger<Processor> log)
        {
            _logger = log;
        }

        [FunctionName("CustomerLoyaltyProcessor")]
        public async Task RunAsync([ServiceBusTrigger("%OrderTopic%", "%CustomerLoyaltySubscription%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message)
        {
            _logger.LogInformation($"C# ServiceBus topic trigger function processed message: {message.MessageId}");

            await Task.CompletedTask;
        }
    }
}
