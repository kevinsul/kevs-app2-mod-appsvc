# 🚨 FIXING Generic ASP.NET Core Error Page

## 🎯 **You're Getting Closer!** 
The app is now running (no more "refused to connect"), but there's an application error.

## ✅ **IMMEDIATE FIX - Enable Detailed Errors:**

### **Option 1: Quick Fix - Set Development Environment**
Update your `web.config` file in the IIS directory:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath=".\InventoryApp.exe" 
                  stdoutLogEnabled="true" 
                  stdoutLogFile=".\logs\stdout" 
                  hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Development" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

### **Option 2: Enable Detailed Errors in Production**
Add this to your `appsettings.json` in the IIS folder:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SQL_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Information",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  },
  "AllowedHosts": "*",
  "DetailedErrors": true
}
```

## 🔍 **MOST LIKELY CAUSES:**

### **#1 Database Connection Issue (90% likely)**
Your app is probably failing to connect to SQL Server.

**Quick Test - Use In-Memory Database:**
Temporarily update `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "InMemory"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

And update `Program.cs` to always use in-memory for testing:
```csharp
// Temporarily force in-memory database
builder.Services.AddDbContext<InventoryContext>(options =>
    options.UseInMemoryDatabase("InventoryDB"));
```

### **#2 Missing Database**
If using SQL Server, the database might not exist.

**Create Database Using Script:**
Run this on your SQL Server:
```sql
-- Connect to your SQL Server and run:
-- C:\scratch\kevs-app2\Scripts\DatabaseSetup.sql
```

### **#3 Permission Issues**
Application pool identity might not have access to SQL Server.

## ✅ **STEP-BY-STEP DIAGNOSIS:**

### **1. Enable Detailed Errors (Do This First!)**
- Update `web.config` with Development environment (shown above)
- Restart Application Pool in IIS
- Browse to app again
- **The error will now show details instead of generic message**

### **2. Check Application Logs**
Create logs folder and check for output:
```cmd
mkdir "C:\inetpub\wwwroot\YourAppFolder\logs"
```

Look for files in the logs folder after trying to access the app.

### **3. Check Windows Event Logs**
- Event Viewer → Windows Logs → Application
- Look for recent .NET Runtime or ASP.NET Core errors

### **4. Test Database Connection**
If you're using SQL Server, test the connection:
```cmd
# From your web server, test SQL connection
sqlcmd -S YOUR_SQL_SERVER_NAME -E -Q "SELECT 1"
```

## 🚀 **QUICK FIXES TO TRY:**

### **Fix #1: Force In-Memory Database**
This will bypass any SQL issues:
```json
// In appsettings.json - temporary fix
{
  "UseInMemoryDatabase": true,
  "ConnectionStrings": {
    "DefaultConnection": "not-used"
  }
}
```

### **Fix #2: Update Connection String**
Make sure your SQL Server name is correct:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

### **Fix #3: Grant SQL Permissions**
On SQL Server, grant permissions to your web server:
```sql
-- Create login for application pool identity
CREATE LOGIN [IIS AppPool\YourAppPoolName] FROM WINDOWS;
USE InventoryDB;
CREATE USER [IIS AppPool\YourAppPoolName] FOR LOGIN [IIS AppPool\YourAppPoolName];
ALTER ROLE db_datareader ADD MEMBER [IIS AppPool\YourAppPoolName];
ALTER ROLE db_datawriter ADD MEMBER [IIS AppPool\YourAppPoolName];
```

## 🎯 **DO THIS FIRST:**
1. **Update web.config** to enable detailed errors (shown above)
2. **Restart the application pool** in IIS
3. **Browse to the app again**
4. **Tell me the detailed error message** - then we can fix it precisely!

The detailed error will tell us exactly what's wrong! 🔍