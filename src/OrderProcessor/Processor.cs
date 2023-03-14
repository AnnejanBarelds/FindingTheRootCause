using Azure.Messaging.ServiceBus;
using DTO;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;

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

            ApplyPromotions(order);

            try
            {
                await ReserveProducts(order);
            }
            catch
            {
                _logger.LogError("Error while processing message with Id {MessageId}", message.MessageId);
                await messageActions.DeadLetterMessageAsync(message, "Error while reserving products");
                throw;
            }

            var @event = GenerateEvent(order);

            await asyncCollector.AddAsync(@event);

            _logger.LogInformation("Processed order with Id {OrderId}", order.Id);
            _logger.LogInformation("C# ServiceBus topic trigger function processed message with Id {MessageId}", message.MessageId);
        }

        private void ApplyPromotions(Order order)
        {
            if (order.Items.Any(item => item.Sku == "sku2"))
            {
                order.Items.Add(new OrderItem
                {
                    Sku = "sku2.1",
                    ProductId = 999,
                    Amount = 1
                });
                _logger.LogInformation("Promotional sku {Sku} added to order with Id {OrderId}", "sku2.1", order.Id);
            }
        }

        private static string[] ExtractProductSkus(Order order)
        {
            return order.Items.SelectMany(item =>
            {
                List<string> skus = new List<string>();
                for (int i = 0; i < item.Amount; i++)
                {
                    skus.Add(item.Sku);
                }
                return skus;
            }).ToArray();
        }

        private async Task ReserveProducts(Order order)
        {
            var products = ExtractProductSkus(order);

            var response = await _inventoryApi.ReserveProducts(products);
            if (!response.IsSuccessStatusCode)
            {
                throw new Exception("Oh noos!!!");
            }
        }

        private dynamic GenerateEvent(Order order)
        {
            using var dependency = _telemetryClient.StartOperation<DependencyTelemetry>("Store event");
            var telemetry = dependency.Telemetry;
            telemetry.Type = "Azure DocumentDB";
            telemetry.Target = _configuration["CosmosDbConnection__accountEndpoint"];

            return new
            {
                // create a random ID
                id = Guid.NewGuid().ToString(),
                OrderItems = order.Items,
                OrderId = order.Id,
                DiagnosticId = Activity.Current?.Id
            };
        }
    }
}
