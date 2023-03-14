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
using System.Linq;

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

            var errors = new List<ObjectResult>();
            IActionResult result = new NoContentResult();

            foreach (var sku in skus)
            {
                if (sku == "sku2.1")
                {
                    log.LogWarning("Stock item {sku} is not eligible for reservations", sku);
                    errors.Add(new BadRequestObjectResult($"Stock item {sku} is not eligible for reservations"));

                }
                else if (sku == "sku4")
                {
                    log.LogWarning("Stock item {sku} is not found", sku);
                    errors.Add(new NotFoundObjectResult($"Stock item {sku} is not found"));
                }
                else
                {
                    log.LogInformation("Stock item {sku} reserved", sku);
                }
            }

            return GenerateResponse(errors);
        }

        private IActionResult GenerateResponse(IEnumerable<ObjectResult> errors)
        {
            if (!errors.Any())
            {
                return new NoContentResult();
            }
            else if (errors.Count() == 1)
            {
                return errors.Single();
            }
            else
            {
                var errorObjects = errors.Select(error => error.Value);
                return new BadRequestObjectResult(errorObjects);
            }
        }
    }
}
