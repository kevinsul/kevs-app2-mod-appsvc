# 🎯 FIXING Production Mode + Missing CSS/Styling

## ✅ **Issue #1: App Works in Development but Not Production**

This confirms it's a **database connection issue**. In Development mode, the app uses in-memory database, but in Production it tries to connect to SQL Server.

### **Fix Option A: Use In-Memory Database (Quick Fix)**
Update your `appsettings.json` in IIS folder:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "InMemory"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

Then you can use Production environment in `web.config`:
```xml
<environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
```

### **Fix Option B: Fix SQL Server Connection**
If you want to use SQL Server, update connection string:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SQL_SERVER_NAME\\SQLEXPRESS;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

Common SQL Server names:
- `localhost\\SQLEXPRESS`
- `.\\SQLEXPRESS` 
- `YOUR_SERVER_NAME\\SQLEXPRESS`
- `YOUR_SERVER_NAME` (for default instance)

## ✅ **Issue #2: Missing CSS/Styling (Static Files Not Loading)**

This is a common IIS + ASP.NET Core issue.

### **Fix #1: Check wwwroot Folder Structure**
Verify your IIS folder has this structure:
```
C:\inetpub\wwwroot\YourAppFolder\
├── InventoryApp.exe
├── InventoryApp.dll
├── web.config
├── wwwroot/                    ← MUST EXIST
│   ├── css/
│   │   ├── bootstrap.min.css   ← CSS files
│   │   └── site.css
│   ├── js/
│   │   ├── bootstrap.bundle.min.js
│   │   └── site.js
│   └── lib/                    ← Bootstrap/jQuery libraries
│       ├── bootstrap/
│       └── jquery/
```

### **Fix #2: Update web.config for Static Files**
Use this enhanced `web.config`:

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
      <staticContent>
        <remove fileExtension=".css" />
        <mimeMap fileExtension=".css" mimeType="text/css" />
        <remove fileExtension=".js" />
        <mimeMap fileExtension=".js" mimeType="application/javascript" />
      </staticContent>
    </system.webServer>
  </location>
</configuration>
```

### **Fix #3: Verify Static Files in Published Output**
Check if static files were included in publish:

```powershell
# Check what's in your publish folder
dir "c:\scratch\kevs-app2\bin\Release\net8.0\publish\wwwroot" -Recurse
```

If wwwroot folder is empty or missing files, the static files weren't published correctly.

### **Fix #4: Force Include Static Files**
Add this to your `InventoryApp.csproj` and republish:

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="9.0.10" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.8" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.8" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.8" />
  </ItemGroup>

  <!-- Ensure static files are included -->
  <ItemGroup>
    <Content Include="wwwroot\**\*" CopyToPublishDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```

Then republish:
```powershell
dotnet publish InventoryApp.csproj -c Release --force
```

## 🚀 **QUICK SOLUTION STEPS:**

### **Step 1: Fix Database Issue**
Update `appsettings.json` in IIS folder:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "InMemory"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
```

### **Step 2: Check Static Files**
Verify `wwwroot` folder exists in your IIS directory with CSS/JS files.

### **Step 3: Use Production web.config**
```xml
<environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
```

### **Step 4: Restart Application Pool**

## 🔍 **Quick Diagnostics:**

**Check if static files are loading:**
- Right-click on webpage → Inspect Element
- Go to Network tab
- Refresh page
- Look for failed requests (red entries) for CSS/JS files

**Test direct static file access:**
- Try: `http://your-server/css/bootstrap.min.css`
- Should show CSS content, not 404 error

Let me know if the static files are missing from your wwwroot folder! 🎨