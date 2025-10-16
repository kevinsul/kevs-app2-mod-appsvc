using Microsoft.EntityFrameworkCore;
using InventoryApp.Data;
using Azure.Identity;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Azure Key Vault configuration for non-development environments
if (!builder.Environment.IsDevelopment())
{
    var keyVaultName = builder.Configuration["KeyVaultName"];
    if (!string.IsNullOrEmpty(keyVaultName))
    {
        var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
        builder.Configuration.AddAzureKeyVault(
            keyVaultUri,
            new DefaultAzureCredential(),
            new AzureKeyVaultConfigurationOptions());
    }
}

// Add services to the container.
builder.Services.AddControllersWithViews();

// Add Entity Framework
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddDbContext<InventoryContext>(options =>
        options.UseInMemoryDatabase("InventoryDB"));
}
else
{
    // Connection string will be loaded from Azure Key Vault secret named "DefaultConnection"
    builder.Services.AddDbContext<InventoryContext>(options =>
        options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
}

var app = builder.Build();

// Seed the in-memory database with sample data for development
if (app.Environment.IsDevelopment())
{
    using (var scope = app.Services.CreateScope())
    {
        var context = scope.ServiceProvider.GetRequiredService<InventoryContext>();
        
        // Add sample data if the database is empty
        if (!context.InventoryItems.Any())
        {
            context.InventoryItems.AddRange(
                new InventoryApp.Models.InventoryItem
                {
                    Name = "Laptop Computer",
                    Description = "Dell Latitude 7420 Business Laptop",
                    Quantity = 15,
                    SerialNumber = "LAP-001"
                },
                new InventoryApp.Models.InventoryItem
                {
                    Name = "Wireless Mouse",
                    Description = "Logitech MX Master 3 Wireless Mouse",
                    Quantity = 50,
                    SerialNumber = "MSE-001"
                },
                new InventoryApp.Models.InventoryItem
                {
                    Name = "USB-C Hub",
                    Description = "Multi-port USB-C Hub with HDMI and Ethernet",
                    Quantity = 25,
                    SerialNumber = "HUB-001"
                },
                new InventoryApp.Models.InventoryItem
                {
                    Name = "Monitor",
                    Description = "24-inch 4K UHD Monitor",
                    Quantity = 8,
                    SerialNumber = "MON-001"
                },
                new InventoryApp.Models.InventoryItem
                {
                    Name = "Keyboard",
                    Description = "Mechanical Gaming Keyboard",
                    Quantity = 30,
                    SerialNumber = "KBD-001"
                }
            );
            context.SaveChanges();
        }
    }
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Inventory}/{action=Index}/{id?}");

app.Run();
