# IIS Deployment Guide for Kev's Inventory Management App

This guide provides step-by-step instructions for deploying Kev's Inventory Management application to Windows Server 2016+ with IIS using Azure Key Vault for secure credential management.

## Prerequisites

### On the Web Server (Windows Server 2016+)
- ✅ Windows Server 2016 or newer
- ✅ IIS with ASP.NET Core Module v2
- ✅ .NET 8.0 Runtime (or .NET 8.0 Hosting Bundle)
- ✅ Access to SQL Server (local or remote)
- ✅ Azure subscription with Key Vault access
- ✅ Managed Identity or Service Principal configured

### On the Database Server (SQL Server 2014+)
- ✅ SQL Server 2014 or newer
- ✅ Network connectivity from web server
- ✅ Appropriate firewall rules (typically port 1433)

### Azure Resources
- ✅ Azure Key Vault created
- ✅ Connection string stored as secret in Key Vault
- ✅ Access policies configured for application identity

## Step-by-Step Deployment

### 1. Set Up Azure Key Vault

#### Create Key Vault
```powershell
# Create resource group if needed
az group create --name InventoryAppRG --location eastus

# Create Key Vault
az keyvault create --name your-keyvault-name --resource-group InventoryAppRG --location eastus
```

#### Store Connection String
```powershell
# Store SQL Server connection string as secret
az keyvault secret set --vault-name your-keyvault-name --name DefaultConnection --value "Server=YOUR_SQL_SERVER;Database=InventoryDB;Integrated Security=true;TrustServerCertificate=true;"
```

### 2. Prepare the Application

On your development machine:

```powershell
# Navigate to project directory
cd c:\scratch\kevs-app2

# Restore packages
dotnet restore kevs-app2.sln

# Publish the application for deployment
dotnet publish kevs-app2.sln -c Release -o .\publish --self-contained false
```

### 3. Set Up the Database (SQL Server)

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

### 4. Configure IIS

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

### 5. Configure Azure Key Vault Integration

**CRITICAL: Secure Configuration with Azure Key Vault**

Update `appsettings.Production.json` in the deployed folder:

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

#### Configure Managed Identity (Recommended)

**Option A: System-Assigned Managed Identity (Azure VM)**
```powershell
# Enable system-assigned managed identity on Azure VM
az vm identity assign --name your-vm-name --resource-group your-rg

# Get the principal ID
$principalId = az vm identity show --name your-vm-name --resource-group your-rg --query principalId -o tsv

# Grant Key Vault access
az keyvault set-policy --name your-keyvault-name --object-id $principalId --secret-permissions get list
```

**Option B: Service Principal (On-Premises IIS)**
```powershell
# Create service principal
az ad sp create-for-rbac --name InventoryAppSP

# Grant Key Vault access
az keyvault set-policy --name your-keyvault-name --spn <app-id> --secret-permissions get list

# Set environment variables in IIS for the service principal
AZURE_CLIENT_ID=<app-id>
AZURE_CLIENT_SECRET=<password>
AZURE_TENANT_ID=<tenant-id>
```

### 6. Configure Web Server Environment

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
          <!-- Only needed for Service Principal authentication -->
          <!-- <environmentVariable name="AZURE_CLIENT_ID" value="your-client-id" /> -->
          <!-- <environmentVariable name="AZURE_CLIENT_SECRET" value="your-client-secret" /> -->
          <!-- <environmentVariable name="AZURE_TENANT_ID" value="your-tenant-id" /> -->
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

### 7. Set Security Permissions

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
```

2. **Grant database permissions:**

```sql
USE InventoryDB;

-- For Windows Authentication
CREATE USER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool] FOR LOGIN [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];
ALTER ROLE db_datareader ADD MEMBER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];
ALTER ROLE db_datawriter ADD MEMBER [WEB-SERVER-NAME\IIS AppPool\InventoryAppPool];
```

3. **Network Configuration:**
   - Ensure SQL Server allows remote connections
   - Configure Windows Firewall on SQL Server to allow port 1433
   - Verify network connectivity from web server to SQL server

### 8. Configure HTTPS (Recommended)

#### Install SSL Certificate
1. Obtain SSL certificate (Let's Encrypt, commercial CA, or self-signed for testing)
2. Install certificate in IIS
3. Add HTTPS binding to the website
4. Configure HTTPS redirection

### 9. Test the Deployment

1. Browse to your application: `http://your-server/` or `https://your-server/`
2. Verify Key Vault connection (check logs for any authentication errors)
3. Verify the inventory page loads correctly
4. Test CRUD operations:
   - Add a new inventory item
   - Edit an existing item
   - Delete an item
   - Verify data persistence

### 10. Monitoring and Maintenance

#### Enable Logging
1. Configure application logging in `appsettings.Production.json`
2. Set up Windows Event Log monitoring
3. Monitor Key Vault access logs
4. Consider Azure Application Insights for comprehensive monitoring

#### Regular Maintenance
- Monitor application performance
- Review security updates for .NET Core
- Backup database regularly
- Monitor disk space and memory usage
- Rotate secrets in Key Vault periodically
- Review Key Vault access policies

## Troubleshooting Common Issues

### Application Won't Start
1. Check Windows Event Logs (Application and System)
2. Verify ASP.NET Core Module is installed
3. Check application pool identity permissions
4. Verify .NET 8.0 Runtime is installed

### Key Vault Access Issues
1. Verify Managed Identity is enabled and configured
2. Check Key Vault access policies
3. Ensure correct Key Vault name in appsettings.Production.json
4. Verify network connectivity to Azure (allow outbound HTTPS)
5. Check Azure Activity Logs for authentication failures

### Database Connection Issues
1. Verify connection string in Key Vault is correct
2. Test connection string manually with SQL Server Management Studio
3. Verify SQL Server is running and accessible
4. Check firewall rules on database server
5. Verify authentication method (Windows vs SQL Server)

### Performance Issues
1. Enable application pool recycling
2. Configure connection pooling
3. Monitor memory usage
4. Consider application warm-up
5. Review Key Vault throttling limits

## Security Checklist

- ✅ Use HTTPS in production
- ✅ Connection strings stored securely in Azure Key Vault
- ✅ Managed Identity enabled (no credentials in code)
- ✅ Regular security updates
- ✅ Principle of least privilege for database access
- ✅ Input validation enabled
- ✅ Error handling doesn't expose sensitive information
- ✅ Consider Web Application Firewall (WAF)
- ✅ Key Vault access policies properly configured
- ✅ Audit logging enabled for Key Vault

## Support

For technical support or questions about this deployment:
1. Check the application logs
2. Review Azure Key Vault access logs
3. Review the README.md file
4. Consult Microsoft's ASP.NET Core deployment documentation
5. Check Azure Key Vault documentation
6. Contact your system administrator or development team

---

**Note**: This guide assumes deployment with Azure Key Vault integration. For legacy deployments without Key Vault, connection strings can be configured directly in appsettings.Production.json (not recommended for production).