using Azure.Messaging.ServiceBus;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using DTO;
using System.Text.Json;
using System;
using System.Collections.Concurrent;

namespace API
{
    public class ApiFunctions
    {
        private static ConcurrentDictionary<int, string> _skuCache = new ConcurrentDictionary<int, string>
        {
            [1] = "sku1",
            [2] = "sku2",
            [3] = "sku4"
        };

        private ILogger _logger;

        public ApiFunctions(ILogger<ApiFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("PlaceOrder")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [ServiceBus("%OrderTopic%", Connection = "ServiceBusConnectionString")] IAsyncCollector<ServiceBusMessage> messages)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var order = JsonSerializer.Deserialize<Order>(body);

            EnrichOrder(order);

            var message = new ServiceBusMessage(JsonSerializer.Serialize(order));
            await messages.AddAsync(message);

            _logger.LogInformation("Order created with Id: {OrderId}", order.Id);

            string responseMessage = $"Order created with Id: {order.Id}";

            return new OkObjectResult(responseMessage);
        }

        private void EnrichOrder(Order order)
        {
            foreach (var item in order.Items)
            {
                _logger.LogInformation("Querying cache for sku for productId {ProductId}...", item.ProductId);
                item.Sku = _skuCache.GetOrAdd(item.ProductId, RetrieveSku);
                _logger.LogInformation("Found sku {Sku} for productId {ProductId}", item.Sku, item.ProductId);
            }
            order.Id = Guid.NewGuid();
        }

        private string RetrieveSku(int productId)
        {
            _logger.LogInformation("Sku for productId {ProductId} not found in cache; querying backend...", productId);
            return $"sku{productId}";
        }
    }
}