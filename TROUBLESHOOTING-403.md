# 🚨 FIXING HTTP Error 403.14 - ASP.NET Core App Not Loading

## 🔍 **Root Cause:**
IIS is treating your app as a static file directory instead of an ASP.NET Core application.

## ✅ **STEP-BY-STEP FIX:**

### **1. Verify ASP.NET Core Hosting Bundle is Installed**
```powershell
# Check if ASP.NET Core Module is installed
Get-WindowsFeature -Name *IIS*
```

**If NOT installed:**
- Download: [ASP.NET Core Hosting Bundle for .NET 8](https://dotnet.microsoft.com/download/dotnet/8.0)
- Install the "Hosting Bundle" (not just Runtime)
- **RESTART IIS**: `iisreset` in elevated command prompt

### **2. Check Application Pool Configuration**
1. Open IIS Manager
2. Go to "Application Pools"
3. Find your app pool
4. **Right-click → Advanced Settings**
5. Verify these settings:
   ```
   .NET CLR Version: No Managed Code
   Managed Pipeline Mode: Integrated
   Enable 32-Bit Applications: False
   Process Model → Identity: ApplicationPoolIdentity (or your service account)
   ```

### **3. Verify Website/Application Configuration**
1. In IIS Manager, go to "Sites"
2. Find your website
3. **Right-click → Convert to Application** (if it's not already an application)
4. Set Application Pool to your ASP.NET Core pool
5. Verify Physical Path points to the folder containing your published files

### **4. Check File Structure in IIS Directory**
Your IIS folder should contain:
```
YourAppFolder/
├── InventoryApp.exe           ← MUST BE PRESENT
├── InventoryApp.dll           ← MUST BE PRESENT  
├── web.config                 ← AUTO-GENERATED
├── appsettings.json
├── appsettings.Production.json
├── wwwroot/                   ← Static files
└── ... other files
```

### **5. Verify web.config is Present**
If `web.config` is missing, create it:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath=".\InventoryApp.exe" stdoutLogEnabled="false" stdoutLogFile=".\logs\stdout" hostingModel="inprocess" />
    </system.webServer>
  </location>
</configuration>
```

### **6. Check Windows Event Logs**
1. Open Event Viewer
2. Go to: **Windows Logs → Application**
3. Look for errors from "IIS AspNetCore Module V2"
4. Check the error details for specific issues

### **7. Enable Detailed Error Messages (Temporarily)**
Add to your `web.config`:
```xml
<system.webServer>
  <httpErrors errorMode="Detailed" />
  <asp scriptErrorSentToBrowser="true"/>
</system.webServer>
```

## 🔧 **QUICK DIAGNOSTIC COMMANDS:**

### **Check IIS Features:**
```powershell
# Run in elevated PowerShell
dism /online /get-features | findstr IIS
```

### **Verify ASP.NET Core Module:**
```powershell
# Check if module is loaded
Get-WebGlobalModule | Where-Object {$_.Name -like "*AspNetCore*"}
```

### **Test Application Pool:**
```powershell
# Check application pool status
Get-IISAppPool | Where-Object {$_.Name -eq "YourAppPoolName"}
```

## 🎯 **MOST COMMON FIXES:**

### **Option 1: Missing Hosting Bundle**
- Install ASP.NET Core 8.0 Hosting Bundle
- Restart IIS: `iisreset`

### **Option 2: Wrong Application Pool Settings**
- Set .NET CLR Version to "No Managed Code"
- Set Managed Pipeline Mode to "Integrated"

### **Option 3: Not Configured as Application**
- Right-click your site folder in IIS
- Select "Convert to Application"
- Set correct Application Pool

### **Option 4: File Permission Issues**
```powershell
# Grant permissions to IIS_IUSRS
icacls "C:\path\to\your\app" /grant "IIS_IUSRS:(OI)(CI)(RX)"
# Grant permissions to Application Pool identity
icacls "C:\path\to\your\app" /grant "IIS AppPool\YourAppPoolName:(OI)(CI)(RX)"
```

## 🚨 **EMERGENCY BYPASS - Test Direct Kestrel**
If IIS still fails, test the app directly:
```powershell
# Navigate to your app folder
cd "C:\path\to\your\published\app"
# Run directly
.\InventoryApp.exe
# Should show: "Now listening on: http://localhost:5000"
```

## 📞 **IF STILL NOT WORKING:**
1. Check Windows Firewall (disable temporarily to test)
2. Verify .NET 8.0 Runtime is installed: `dotnet --list-runtimes`
3. Try creating a new simple test app to verify IIS + ASP.NET Core works
4. Check antivirus software blocking execution

---

**Most likely fix: Install ASP.NET Core Hosting Bundle and restart IIS!** 🚀