using System;
using System.Diagnostics;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace OrderProcessor
{
    public class Processor
    {
        private readonly ILogger<Processor> _logger;
        private readonly TelemetryClient _telemetryClient;
        private readonly IConfiguration _configuration;

        public Processor(ILogger<Processor> log, TelemetryConfiguration telemetryConfiguration, IConfiguration configuration)
        {
            _logger = log;
            _telemetryClient = new TelemetryClient(telemetryConfiguration);
            _configuration = configuration;
        }

        [FunctionName("OrderProcessor")]
        public async Task RunAsync(
            [ServiceBusTrigger("%OrderTopic%", "%OrderProcessingSubscription%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message,
            [CosmosDB("%EventsDB%", "%OrderEventsContainer%", Connection = "CosmosDbConnection")] IAsyncCollector<dynamic> asyncCollector)
        {
            _logger.LogInformation($"C# ServiceBus topic trigger function processing message: {message.MessageId}");

            using var dependency = _telemetryClient.StartOperation<DependencyTelemetry>("Store event");
            var telemetry = dependency.Telemetry;
            telemetry.Type = "Azure DocumentDB";
            telemetry.Target = _configuration["CosmosDbConnection__accountEndpoint"];

            await asyncCollector.AddAsync(new
            {
                // create a random ID
                id = Guid.NewGuid().ToString(),
                text = "SomeText",
                OrderId = Guid.NewGuid().ToString(),
                DiagnosticId = Activity.Current?.Id
            });

            _logger.LogInformation($"C# ServiceBus topic trigger function processed message: {message.MessageId}");
        }
    }
}
