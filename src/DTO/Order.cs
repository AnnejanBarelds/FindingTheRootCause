namespace DTO
{
    public class Order
    {
        public Guid Id { get; set; }

        public IEnumerable<OrderItem> Items { get; set; }
    }
}