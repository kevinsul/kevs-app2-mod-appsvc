# 🚨 FIXING "Refused to Connect" Error

## 🔍 **Possible Causes:**
1. Application failing to start
2. Wrong URL/Port
3. Firewall blocking connection
4. Application pool stopped
5. Database connection issues

## ✅ **STEP-BY-STEP DIAGNOSIS:**

### **1. Check Application Pool Status**
In IIS Manager:
1. Go to "Application Pools"
2. Find your app pool
3. **Status should be "Started"**
4. If "Stopped" → Right-click → Start

### **2. Check Windows Event Logs (CRITICAL)**
1. Open **Event Viewer**
2. Go to: **Windows Logs → Application**
3. Look for recent errors from:
   - **"IIS AspNetCore Module V2"**
   - **"Application Error"**
   - **".NET Runtime"**

**Tell me what errors you see here!** This will show the exact problem.

### **3. Test Direct Application Access**
Try accessing different URLs:
```
http://your-server-ip/
http://your-server-ip/Inventory
http://localhost/ (from the server itself)
```

### **4. Check If App is Actually Running**
On your web server, open Task Manager:
- Look for **"InventoryApp.exe"** in processes
- If not running → App failed to start

### **5. Test Database Connection**
The app might be failing because it can't connect to SQL Server.

**Quick Test - Update Connection String:**
Edit `appsettings.json` in your IIS folder and temporarily use in-memory database:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "InMemoryDatabase"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

Then restart the application pool.

### **6. Enable Detailed Logging**
Create/update `web.config` in your IIS folder:

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
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
```

Create logs folder:
```powershell
mkdir "C:\inetpub\wwwroot\YourAppFolder\logs"
```

### **7. Check Firewall**
**Temporarily disable Windows Firewall** to test:
```powershell
# Run as Administrator
netsh advfirewall set allprofiles state off
# Test your app
# Then re-enable: netsh advfirewall set allprofiles state on
```

### **8. Test Application Directly (Bypass IIS)**
On your web server:
```powershell
# Navigate to your app folder
cd "C:\inetpub\wwwroot\YourAppFolder"

# Run directly
.\InventoryApp.exe

# Should show something like:
# "Now listening on: http://localhost:5000"
# "Application started. Press Ctrl+C to shut down."
```

If this works but IIS doesn't, it's an IIS configuration issue.

## 🎯 **MOST LIKELY CAUSES:**

### **#1 Database Connection Failed**
- SQL Server not accessible from web server
- Wrong connection string
- Authentication failure

### **#2 Missing Dependencies**
- ASP.NET Core Hosting Bundle not installed
- .NET 8.0 Runtime missing

### **#3 Permission Issues**
- Application pool identity can't access files
- SQL Server permissions missing

### **#4 Port/URL Issues**
- Trying wrong URL
- Port conflicts
- SSL/HTTPS configuration issues

## 🚨 **IMMEDIATE ACTIONS:**

1. **Check Event Viewer Application logs** - This will tell us exactly what's failing
2. **Test direct app execution** - Run `InventoryApp.exe` directly
3. **Try in-memory database** - Temporarily bypass SQL connection
4. **Check application pool status** - Ensure it's started

**Please check the Windows Event Logs first and tell me what errors you see - that will pinpoint the exact issue!** 🔍