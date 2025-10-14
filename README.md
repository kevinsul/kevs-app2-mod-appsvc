# Kev's Inventory Management Application

A simple ASP.NET Core MVC application for managing inventory items with full CRUD operations.

## Features

- **Display Inventory**: View all inventory items in a responsive table
- **Add Items**: Create new inventory items with validation
- **Edit Items**: Update existing inventory item details
- **Delete Items**: Remove inventory items with confirmation
- **Serial Number Validation**: Ensures unique serial numbers across all items

## Database Schema

The application uses a SQL Server database with the following schema:

### InventoryItems Table
- `Id` (int, Primary Key, Auto-increment)
- `Name` (nvarchar(100), Required)
- `Description` (nvarchar(500), Optional)
- `Quantity` (int, Required, Must be >= 0)
- `SerialNumber` (nvarchar(50), Required, Unique)

## Configuration

### Connection String

Update the connection string in `appsettings.json` to point to your SQL Server instance:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_DATABASE_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

### Alternative Connection String Options

For SQL Server Authentication:
```
Server=YOUR_DATABASE_SERVER;Database=InventoryDB;User Id=YOUR_USERNAME;Password=YOUR_PASSWORD;TrustServerCertificate=true;
```

For Azure SQL Database:
```
Server=tcp:yourserver.database.windows.net,1433;Initial Catalog=InventoryDB;Persist Security Info=False;User ID=yourusername;Password=yourpassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

## Development Setup

### Prerequisites
- .NET 8.0 SDK
- SQL Server 2014 or newer
- Visual Studio 2022 or VS Code

### Getting Started

1. **Clone the repository** (if using version control)

2. **Restore packages**:
   ```bash
   dotnet restore
   ```

3. **Update connection string** in `appsettings.json`

4. **Create and run database migrations**:
   ```bash
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```

5. **Run the application**:
   ```bash
   dotnet run
   ```

## Deployment to IIS (Windows Server 2016+)

### Prerequisites
- Windows Server 2016 or newer
- IIS with ASP.NET Core Module v2
- .NET 8.0 Runtime
- SQL Server 2014 or newer (can be on separate server)

### Deployment Steps

1. **Publish the application**:
   ```bash
   dotnet publish -c Release -o ./publish
   ```

2. **Copy files** to your web server

3. **Create IIS Application**:
   - Create a new website or application in IIS
   - Set the physical path to your published files
   - Configure the application pool to use "No Managed Code"

4. **Configure Database**:
   - Ensure SQL Server is accessible from the web server
   - Update connection string in `appsettings.json` for production
   - Run database migrations on production database:
     ```bash
     dotnet ef database update --connection "YourProductionConnectionString"
     ```

5. **Set Permissions**:
   - Grant IIS_IUSRS read access to application files
   - Grant necessary database permissions to the application identity

### Production Configuration

Create `appsettings.Production.json` for production-specific settings:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=PROD_DB_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

## Security Considerations

- Use Windows Authentication or strong SQL authentication
- Enable HTTPS in production
- Keep connection strings secure (consider Azure Key Vault for cloud deployments)
- Regularly update packages for security patches

## Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Verify SQL Server is running and accessible
   - Check connection string format
   - Ensure firewall allows connections

2. **Migration Errors**:
   - Verify database permissions
   - Check if database exists
   - Ensure EF Core tools are installed

3. **IIS Deployment Issues**:
   - Verify ASP.NET Core Module is installed
   - Check application pool settings
   - Review Windows Event Logs

## Technology Stack

- **Framework**: ASP.NET Core 8.0 MVC
- **Database**: Entity Framework Core with SQL Server
- **Frontend**: Bootstrap 5, Razor Views
- **Icons**: Font Awesome
- **Target Environment**: Windows Server 2016+ with IIS

## License

This project is open source and available under the MIT License.