# IIS Deployment Guide for Kev's Inventory Management App

This guide provides step-by-step instructions for deploying Kev's Inventory Management application to Windows Server 2016+ with IIS.

## Prerequisites

### On the Web Server (Windows Server 2016+)
- ✅ Windows Server 2016 or newer
- ✅ IIS with ASP.NET Core Module v2
- ✅ .NET 8.0 Runtime (or .NET 8.0 Hosting Bundle)
- ✅ Access to SQL Server (local or remote)

### On the Database Server (SQL Server 2014+)
- ✅ SQL Server 2014 or newer
- ✅ Network connectivity from web server
- ✅ Appropriate firewall rules (typically port 1433)

## Step-by-Step Deployment

### 1. Prepare the Application

On your development machine:

```powershell
# Navigate to project directory
cd c:\scratch\kevs-app2

# Restore packages (when network is available)
dotnet restore

# Publish the application for deployment
dotnet publish -c Release -o .\publish --self-contained false
```

### 2. Set Up the Database

#### Option A: Using Entity Framework Migrations
```powershell
# Update connection string in appsettings.Production.json
# Then run migrations
dotnet ef database update --connection "YourProductionConnectionString"
```

#### Option B: Using SQL Script (Recommended for Production)
1. Connect to your SQL Server using SQL Server Management Studio
2. Run the script located at `Scripts\DatabaseSetup.sql`
3. Verify the database and tables were created successfully

### 3. Configure IIS

#### Install ASP.NET Core Module
1. Download and install the ASP.NET Core Hosting Bundle from Microsoft
2. Restart IIS: `iisreset`

#### Create Application Pool
1. Open IIS Manager
2. Right-click "Application Pools" → "Add Application Pool"
3. Name: `InventoryAppPool`
4. .NET CLR Version: `No Managed Code`
5. Managed Pipeline Mode: `Integrated`
6. Start Mode: `AlwaysRunning` (recommended for production)

#### Create Website/Application
1. Copy published files to web server (e.g., `C:\inetpub\wwwroot\InventoryApp`)
2. In IIS Manager, right-click "Sites" → "Add Website"
3. Site Name: `Kev's Inventory Management`
4. Application Pool: `InventoryAppPool`
5. Physical Path: `C:\inetpub\wwwroot\InventoryApp`
6. Binding: HTTP/HTTPS as needed

### 4. Configure Connection String

Create or update `appsettings.Production.json` in the deployed folder:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_DATABASE_SERVER;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  }
}
```

#### Connection String Examples:

**Windows Authentication (Recommended):**
```
Server=DB-SERVER-NAME;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;
```

**SQL Server Authentication:**
```
Server=DB-SERVER-NAME;Database=InventoryDB;User Id=your_username;Password=your_password;TrustServerCertificate=true;
```

**Azure SQL Database:**
```
Server=tcp:yourserver.database.windows.net,1433;Initial Catalog=InventoryDB;Persist Security Info=False;User ID=your_username;Password=your_password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

### 5. Set Security Permissions

#### File System Permissions
1. Grant `IIS_IUSRS` read and execute permissions to the application folder
2. Grant `IIS AppPool\InventoryAppPool` read and execute permissions to the application folder

```powershell
# PowerShell commands to set permissions
icacls "C:\inetpub\wwwroot\InventoryApp" /grant "IIS_IUSRS:(OI)(CI)(RX)"
icacls "C:\inetpub\wwwroot\InventoryApp" /grant "IIS AppPool\InventoryAppPool:(OI)(CI)(RX)"
```

#### Database Permissions
1. Create a login for the application pool identity
2. Grant `db_datareader` and `db_datawriter` roles
3. Grant `db_ddladmin` role if using EF migrations in production

### 6. Configure HTTPS (Recommended)

#### Install SSL Certificate
1. Obtain SSL certificate (Let's Encrypt, commercial CA, or self-signed for testing)
2. Install certificate in IIS
3. Add HTTPS binding to the website
4. Configure HTTPS redirection

#### Update appsettings.Production.json
```json
{
  "Kestrel": {
    "Endpoints": {
      "Https": {
        "Url": "https://localhost:443"
      }
    }
  }
}
```

### 7. Test the Deployment

1. Browse to your application: `http://your-server/` or `https://your-server/`
2. Verify the inventory page loads correctly
3. Test CRUD operations:
   - Add a new inventory item
   - Edit an existing item
   - Delete an item
   - Verify data persistence

### 8. Monitoring and Maintenance

#### Enable Logging
1. Configure application logging in `appsettings.Production.json`
2. Set up Windows Event Log monitoring
3. Consider structured logging with Serilog for production

#### Regular Maintenance
- Monitor application performance
- Review security updates for .NET Core
- Backup database regularly
- Monitor disk space and memory usage

## Troubleshooting Common Issues

### Application Won't Start
1. Check Windows Event Logs (Application and System)
2. Verify ASP.NET Core Module is installed
3. Check application pool identity permissions
4. Verify .NET 8.0 Runtime is installed

### Database Connection Issues
1. Test connection string with SQL Server Management Studio
2. Verify SQL Server is running and accessible
3. Check firewall rules on database server
4. Verify authentication method (Windows vs SQL Server)

### Performance Issues
1. Enable application pool recycling
2. Configure connection pooling
3. Monitor memory usage
4. Consider application warm-up

## Security Checklist

- ✅ Use HTTPS in production
- ✅ Keep connection strings secure
- ✅ Regular security updates
- ✅ Principle of least privilege for database access
- ✅ Input validation enabled
- ✅ Error handling doesn't expose sensitive information
- ✅ Consider Web Application Firewall (WAF)

## Support

For technical support or questions about this deployment:
1. Check the application logs
2. Review the README.md file
3. Consult Microsoft's ASP.NET Core deployment documentation
4. Contact your system administrator or development team

---

**Note**: This guide assumes a standard Windows Server environment. Adjust paths and configurations as needed for your specific infrastructure.