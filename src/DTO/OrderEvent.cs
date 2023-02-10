using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace DTO
{
    public class OrderEvent
    {
        public string id { get; set; }

        public IEnumerable<OrderItem> Items { get; set; }

        public Guid OrderId { get; set; }

        public string DiagnosticId { get; set; }

        public void Trace()
        {
            var parts = DiagnosticId?.Split('-');
            if (parts != null && parts.Length == 4)
            {
                var existinglinksTag = Activity.Current?.GetTagItem("_MS.links");
                var links = existinglinksTag != null
                    ? JsonSerializer.Deserialize<List<OperationLink>>(existinglinksTag.ToString())
                    : new List<OperationLink>();

                links.Add(new OperationLink(parts[1], parts[2]));

                Activity.Current?.SetTag("_MS.links", JsonSerializer.Serialize(links));
            }
        }

        private readonly record struct OperationLink(string operation_Id, string id);
    }
}
