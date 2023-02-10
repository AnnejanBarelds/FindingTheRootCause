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

namespace API
{
    public class ApiFunctions
    {
        [FunctionName("PlaceOrder")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [ServiceBus("%OrderTopic%", Connection = "ServiceBusConnectionString")] IAsyncCollector<ServiceBusMessage> messages,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var order = JsonSerializer.Deserialize<Order>(body);

            order.Id = Guid.NewGuid();

            var message = new ServiceBusMessage(JsonSerializer.Serialize(order));
            await messages.AddAsync(message);

            log.LogInformation("Order created with Id: {OrderId}", order.Id);

            string responseMessage = $"Order created with Id: {order.Id}";

            return new OkObjectResult(responseMessage);
        }
    }
}
