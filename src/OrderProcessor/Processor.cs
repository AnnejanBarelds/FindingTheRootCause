using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using DTO;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Amqp.Framing;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace OrderProcessor
{
    public class Processor
    {
        private readonly ILogger<Processor> _logger;
        private readonly TelemetryClient _telemetryClient;
        private readonly IConfiguration _configuration;
        private readonly IInventoryApi _inventoryApi;

        public Processor(ILogger<Processor> log, TelemetryConfiguration telemetryConfiguration, IConfiguration configuration, IInventoryApi inventoryApi)
        {
            _logger = log;
            _telemetryClient = new TelemetryClient(telemetryConfiguration);
            _configuration = configuration;
            _inventoryApi = inventoryApi;
        }

        [FunctionName("OrderProcessor")]
        public async Task RunAsync(
            [ServiceBusTrigger("%OrderTopic%", "%OrderProcessingSubscription%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message, ServiceBusMessageActions messageActions,
            [CosmosDB("%EventsDB%", "%OrderEventsContainer%", Connection = "CosmosDbConnection")] IAsyncCollector<dynamic> asyncCollector)
        {
            _logger.LogInformation("C# ServiceBus topic trigger function processing message with Id {MessageId}", message.MessageId);

            var order = message.Body.ToObjectFromJson<Order>();

            var products = order.Items.SelectMany(item =>
            {
                List<string> skus = new List<string>();
                for (int i = 0; i < item.Amount; i++)
                {
                    skus.Add(item.Sku);
                }
                return skus;
            }).ToArray();

            var response = await _inventoryApi.ReserveProducts(products);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Error while processing message with Id {MessageId}", message.MessageId);

                await messageActions.DeadLetterMessageAsync(message, "Error while reserving products");
                throw new Exception("Oh noos!!!");
            }

            using var dependency = _telemetryClient.StartOperation<DependencyTelemetry>("Store event");
            var telemetry = dependency.Telemetry;
            telemetry.Type = "Azure DocumentDB";
            telemetry.Target = _configuration["CosmosDbConnection__accountEndpoint"];

            await asyncCollector.AddAsync(new
            {
                // create a random ID
                id = Guid.NewGuid().ToString(),
                OrderItems = order.Items,
                OrderId = order.Id,
                DiagnosticId = Activity.Current?.Id
            });

            _logger.LogInformation("Processed order with Id: {OrderId}", order.Id);
            _logger.LogInformation("C# ServiceBus topic trigger function processed message with Id {MessageId}", message.MessageId);
        }
    }
}
