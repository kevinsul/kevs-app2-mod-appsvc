using Microsoft.EntityFrameworkCore;
using InventoryApp.Models;

namespace InventoryApp.Data
{
    public class InventoryContext : DbContext
    {
        public InventoryContext(DbContextOptions<InventoryContext> options) : base(options)
        {
        }

        public DbSet<InventoryItem> InventoryItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure unique constraint on SerialNumber
            modelBuilder.Entity<InventoryItem>()
                .HasIndex(i => i.SerialNumber)
                .IsUnique();

            // Configure table and column names
            modelBuilder.Entity<InventoryItem>()
                .ToTable("InventoryItems");

            modelBuilder.Entity<InventoryItem>()
                .Property(i => i.Name)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<InventoryItem>()
                .Property(i => i.Description)
                .HasMaxLength(500);

            modelBuilder.Entity<InventoryItem>()
                .Property(i => i.SerialNumber)
                .HasMaxLength(50)
                .IsRequired();
        }
    }
}