using System.ComponentModel.DataAnnotations;

namespace InventoryApp.Models
{
    public class InventoryItem
    {
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string Description { get; set; } = string.Empty;

        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity must be a positive number")]
        public int Quantity { get; set; }

        [Required]
        [StringLength(50)]
        public string SerialNumber { get; set; } = string.Empty;
    }
}