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

# Restore packages
dotnet restore

# Publish the application for deployment
dotnet publish InventoryApp.csproj -c Release -o .\publish --self-contained false
```

### 2. Set Up the Database (SQL Server)

#### Option A: Using SQL Script (Recommended for Production)
1. Connect to your **SQL Server** using SQL Server Management Studio
2. Run the script located at `Scripts\DatabaseSetup.sql`
3. Verify the database and tables were created successfully
4. Create application login and grant permissions (see Security section below)

#### Option B: Using Entity Framework Migrations
```powershell
# From development machine, targeting SQL Server
dotnet ef database update --connection "Server=YOUR_SQL_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
```

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

**CRITICAL: Update for your SQL Server**

Create or update `appsettings.Production.json` in the deployed folder:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SQL_SERVER_NAME;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  }
}
```

#### Connection String Examples for Separate SQL Server:

**Windows Authentication (Recommended):**
```
Server=SQL-SERVER-NAME;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;
```

**SQL Server Authentication:**
```
Server=SQL-SERVER-NAME;Database=InventoryDB;User Id=your_username;Password=your_password;TrustServerCertificate=true;
```

**SQL Server with Instance:**
```
Server=SQL-SERVER-NAME\SQLEXPRESS;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;
```

**SQL Server with IP Address:**
```
Server=192.168.1.100,1433;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;
```

### 5. Configure Web Server Environment

**CRITICAL: Set Production Environment**

Update your `web.config` in the deployed folder:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath=".\InventoryApp.exe" 
                  stdoutLogEnabled="false" 
                  stdoutLogFile=".\logs\stdout" 
                  hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

### 6. Set Security Permissions

#### File System Permissions (Web Server)
1. Grant `IIS_IUSRS` read and execute permissions to the application folder
2. Grant `IIS AppPool\InventoryAppPool` read and execute permissions to the application folder

```powershell
# PowerShell commands to set permissions on Web Server
icacls "C:\inetpub\wwwroot\InventoryApp" /grant "IIS_IUSRS:(OI)(CI)(RX)"
icacls "C:\inetpub\wwwroot\InventoryApp" /grant "IIS AppPool\InventoryAppPool:(OI)(CI)(RX)"
```

#### Database Permissions (SQL Server)

**CRITICAL FOR SEPARATE SQL SERVER SETUP:**

1. **On SQL Server**, create a login for the web server application pool:

```sql
-- Option A: Windows Authentication (Web Server Machine Account)
-- Replace 'WEB-SERVER-NAME' with your actual web server computer name
CREATE LOGIN [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool] FROM WINDOWS;

-- Option B: Windows Authentication (Custom Service Account)
-- If using a custom service account for the app pool
CREATE LOGIN [DOMAIN\ServiceAccountName] FROM WINDOWS;

-- Option C: SQL Server Authentication (create SQL user)
CREATE LOGIN InventoryAppUser WITH PASSWORD = 'StrongPassword123!';
```

2. **Grant database permissions:**

```sql
USE InventoryDB;

-- For Windows Authentication
CREATE USER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool] FOR LOGIN [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];
ALTER ROLE db_datareader ADD MEMBER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];
ALTER ROLE db_datawriter ADD MEMBER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];

-- For SQL Authentication
CREATE USER InventoryAppUser FOR LOGIN InventoryAppUser;
ALTER ROLE db_datareader ADD MEMBER InventoryAppUser;
ALTER ROLE db_datawriter ADD MEMBER InventoryAppUser;
```

3. **Network Configuration:**
   - Ensure SQL Server allows remote connections
   - Configure Windows Firewall on SQL Server to allow port 1433
   - Verify network connectivity from web server to SQL server

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