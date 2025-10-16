# Kev's Inventory Management Application

A simple ASP.NET Core MVC application for managing inventory items with full CRUD operations.

## Features

- **Display Inventory**: View all inventory items in a responsive table
- **Add Items**: Create new inventory items with validation
- **Edit Items**: Update existing inventory item details
- **Delete Items**: Remove inventory items with confirmation
- **Serial Number Validation**: Ensures unique serial numbers across all items
- **Secure Credentials**: Uses Azure Key Vault to securely store connection strings and secrets

## Database Schema

The application uses a SQL Server database with the following schema:

### InventoryItems Table
- `Id` (int, Primary Key, Auto-increment)
- `Name` (nvarchar(100), Required)
- `Description` (nvarchar(500), Optional)
- `Quantity` (int, Required, Must be >= 0)
- `SerialNumber` (nvarchar(50), Required, Unique)

## Configuration

### Azure Key Vault Integration

This application uses Azure Key Vault to securely manage connection strings and other sensitive configuration data in production environments.

#### Prerequisites for Production
- Azure subscription
- Azure Key Vault resource created
- Managed Identity or Service Principal configured for authentication
- Connection string stored as a secret named `DefaultConnection` in Key Vault

#### Configuration Setup

1. **Update `appsettings.Production.json`** with your Key Vault name:

```json
{
  "KeyVaultName": "your-keyvault-name",
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  }
}
```

2. **Store the connection string in Azure Key Vault**:
   - Secret Name: `DefaultConnection`
   - Secret Value: Your SQL Server connection string

3. **Configure Authentication**:
   - For Azure App Service: Enable Managed Identity
   - For local development: Use Azure CLI (`az login`) or Visual Studio authentication

### Development Environment

For development, the application uses an in-memory database with sample data. No Azure Key Vault configuration is required for local development.

### Legacy Connection String Configuration (Not Recommended)

If you need to use local connection strings (not recommended for production):

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_DATABASE_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

## 📁 Project Structure
```
kevs-app2/
├── Controllers/InventoryController.cs   # CRUD operations
├── Models/InventoryItem.cs             # Data model
├── Views/Inventory/                    # UI pages
├── Data/InventoryContext.cs            # Entity Framework context
├── Scripts/DatabaseSetup.sql           # Database creation script
├── wwwroot/                           # Static files (CSS, JS)
├── appsettings.json                   # Development configuration
└── appsettings.Production.json         # Production configuration (with Key Vault)
```

## 🚀 Quick Start

### Development Setup (Local)
1. **Restore packages:**
   ```bash
   dotnet restore kevs-app2.sln
   ```

2. **Run the application:**
   ```bash
   dotnet run --project InventoryApp.csproj
   ```
   The app will start with an in-memory database and sample data.

3. **Browse to:** `https://localhost:5001` or `http://localhost:5000`

### Production Deployment to Azure
1. **Create Azure Key Vault**:
   ```bash
   az keyvault create --name your-keyvault-name --resource-group your-rg --location eastus
   ```

2. **Store connection string as secret**:
   ```bash
   az keyvault secret set --vault-name your-keyvault-name --name DefaultConnection --value "Server=your-server;Database=InventoryDB;..."
   ```

3. **Publish the application**:
   ```bash
   dotnet publish kevs-app2.sln -c Release -o ./publish
   ```

4. **Deploy to Azure App Service** and enable Managed Identity

5. **Grant Key Vault access to the Managed Identity**:
   ```bash
   az keyvault set-policy --name your-keyvault-name --object-id <managed-identity-id> --secret-permissions get list
   ```

### Prerequisites
- .NET 8.0 SDK
- SQL Server 2014 or newer (or Azure SQL Database)
- Visual Studio 2022 or VS Code
- Azure subscription (for production deployment)

## Deployment to IIS (Windows Server 2016+)

### Prerequisites
- Windows Server 2016 or newer
- IIS with ASP.NET Core Module v2
- .NET 8.0 Runtime
- SQL Server 2014 or newer (can be on separate server)
- Azure Key Vault for secure credential storage

### Deployment Steps

1. **Publish the application**:
   ```bash
   dotnet publish -c Release -o ./publish
   ```

2. **Configure Azure Key Vault** with connection string secret

3. **Copy files** to your web server

4. **Create IIS Application**:
   - Create a new website or application in IIS
   - Set the physical path to your published files
   - Configure the application pool to use "No Managed Code"

5. **Configure Managed Identity or Service Principal** for Key Vault access

6. **Set environment variable** in IIS:
   - `ASPNETCORE_ENVIRONMENT` = `Production`

7. **Test the application** to verify Key Vault integration

## Security Considerations

- ✅ **Azure Key Vault**: Connection strings and secrets are stored securely in Azure Key Vault
- ✅ **Managed Identity**: Uses Azure Managed Identity for passwordless authentication to Key Vault
- ✅ **No Hardcoded Secrets**: No connection strings or credentials in source code or configuration files
- ✅ **HTTPS**: Enable HTTPS in production
- ✅ **Regular Updates**: Keep packages updated for security patches

## Troubleshooting

### Common Issues

1. **Key Vault Access Errors**:
   - Verify Managed Identity is enabled
   - Check Key Vault access policies
   - Ensure correct Key Vault name in configuration

2. **Database Connection Errors**:
   - Verify SQL Server is running and accessible
   - Check connection string in Key Vault
   - Ensure firewall allows connections

3. **Authentication Issues**:
   - For local development, run `az login`
   - Verify Managed Identity permissions in Azure
   - Check Azure RBAC role assignments

## Technology Stack

- **Framework**: ASP.NET Core 8.0 MVC
- **Database**: Entity Framework Core with SQL Server
- **Security**: Azure Key Vault with Managed Identity
- **Frontend**: Bootstrap 5, Razor Views
- **Icons**: Font Awesome
- **Target Environment**: Windows Server 2016+ with IIS or Azure App Service

## License

This project is open source and available under the MIT License.