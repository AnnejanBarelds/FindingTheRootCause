using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DTO
{
    public class OrderItem
    {
        public string Sku { get; set; }

        public int ProductId { get; set; }

        public int Amount { get; set; }
    }
}
