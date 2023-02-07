using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace OrderProcessor
{
    public class Processor
    {
        private readonly ILogger<Processor> _logger;

        public Processor(ILogger<Processor> log)
        {
            _logger = log;
        }

        [FunctionName("OrderProcessor")]
        public async Task RunAsync([ServiceBusTrigger("%OrderTopic%", "%OrderProcessingSubscription%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message)
        {
            _logger.LogInformation($"C# ServiceBus topic trigger function processed message: {message.MessageId}");

            await Task.CompletedTask;
        }
    }
}
