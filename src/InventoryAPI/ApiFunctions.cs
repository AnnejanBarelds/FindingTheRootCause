using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Text.Json;

namespace InventoryAPI
{
    public class ApiFunctions
    {
        [FunctionName("Reservations")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var skus = JsonSerializer.Deserialize<IEnumerable<string>>(body);

            bool hasClientErrors = false;

            foreach (var sku in skus)
            {
                if (sku == "sku2")
                {
                    log.LogWarning("Stock item {sku} not found", sku);
                    hasClientErrors = true;
                }
                else
                {
                    log.LogInformation("Stock item {sku} reserved", sku);
                }
            }

            return hasClientErrors ? new NotFoundResult() : new NoContentResult();
        }
    }
}
