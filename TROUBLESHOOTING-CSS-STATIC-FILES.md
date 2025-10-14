# 🎨 FIXING CSS/Styling Issues in IIS

## 🔍 **CSS Not Loading - Common IIS Issue**

Since your app connects to the database but styling is missing, the static files (CSS/JS) aren't being served properly by IIS.

## ✅ **STEP-BY-STEP FIXES:**

### **Fix #1: Verify Static Files Are Present**
Check your IIS folder structure:
```
C:\inetpub\wwwroot\YourAppFolder\
├── InventoryApp.exe
├── InventoryApp.dll
├── web.config
├── wwwroot/                    ← MUST BE HERE
│   ├── css/
│   │   └── site.css           ← Check this exists
│   ├── js/
│   │   └── site.js
│   └── lib/
│       ├── bootstrap/
│       │   ├── css/
│       │   │   └── bootstrap.min.css  ← Bootstrap CSS
│       │   └── js/
│       │       └── bootstrap.bundle.min.js
│       └── jquery/
│           └── jquery.min.js
```

### **Fix #2: Test Direct CSS Access**
Try accessing CSS files directly in your browser:
```
http://your-server/css/site.css
http://your-server/lib/bootstrap/css/bootstrap.min.css
```

**If you get 404 errors**, the static files aren't being served.

### **Fix #3: Enhanced web.config for Static Files**
Update your `web.config` to explicitly handle static files:

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
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Development" />
        </environmentVariables>
      </aspNetCore>
      
      <!-- Static file handling -->
      <staticContent>
        <remove fileExtension=".css" />
        <mimeMap fileExtension=".css" mimeType="text/css" />
        <remove fileExtension=".js" />
        <mimeMap fileExtension=".js" mimeType="application/javascript" />
        <remove fileExtension=".woff" />
        <mimeMap fileExtension=".woff" mimeType="font/woff" />
        <remove fileExtension=".woff2" />
        <mimeMap fileExtension=".woff2" mimeType="font/woff2" />
      </staticContent>
      
      <!-- Enable static file caching -->
      <httpProtocol>
        <customHeaders>
          <add name="Cache-Control" value="public, max-age=31536000" />
        </customHeaders>
      </httpProtocol>
    </system.webServer>
  </location>
</configuration>
```

### **Fix #4: Alternative - Use IIS Static File Handler**
Add this section to your `web.config` before the aspNetCore handler:

```xml
<handlers>
  <!-- Static files first -->
  <add name="StaticFileModuleHtml" path="*.html" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleCss" path="*.css" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleJs" path="*.js" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleJpeg" path="*.jpeg" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleJpg" path="*.jpg" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModulePng" path="*.png" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleGif" path="*.gif" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleWoff" path="*.woff" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  <add name="StaticFileModuleWoff2" path="*.woff2" verb="*" modules="StaticFileModule" resourceType="File" requireAccess="Read" />
  
  <!-- ASP.NET Core handler -->
  <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
</handlers>
```

### **Fix #5: Check Browser Developer Tools**
1. **Right-click on your webpage → Inspect Element**
2. **Go to Network tab**
3. **Refresh the page**
4. **Look for failed requests (red entries)**

You'll see something like:
```
Failed to load resource: the server responded with a status of 404 (Not Found)
/css/site.css
/lib/bootstrap/css/bootstrap.min.css
```

### **Fix #6: Force Copy Static Files**
If static files are missing, recopy them:

```powershell
# Copy just the wwwroot folder
Copy-Item "c:\scratch\kevs-app2\bin\Release\net8.0\publish\wwwroot" "C:\inetpub\wwwroot\YourAppFolder\" -Recurse -Force
```

### **Fix #7: IIS URL Rewrite (If Available)**
If you have URL Rewrite module installed:

```xml
<system.webServer>
  <rewrite>
    <rules>
      <rule name="Static Files" stopProcessing="true">
        <match url="^(css|js|lib|images)/.*" />
        <action type="None" />
      </rule>
    </rules>
  </rewrite>
  <!-- ... rest of config -->
</system.webServer>
```

## 🚀 **QUICK DIAGNOSTIC STEPS:**

### **1. Check Files Exist:**
```cmd
dir "C:\inetpub\wwwroot\YourAppFolder\wwwroot\lib\bootstrap\css" /s
```
Should show `bootstrap.min.css`

### **2. Test Direct Access:**
In browser: `http://your-server/lib/bootstrap/css/bootstrap.min.css`

### **3. Check IIS Static Content Feature:**
In IIS Manager:
- Select your server
- Double-click "MIME Types"
- Verify `.css` is mapped to `text/css`

### **4. Check Permissions:**
```powershell
icacls "C:\inetpub\wwwroot\YourAppFolder\wwwroot" /grant "IIS_IUSRS:(OI)(CI)(RX)"
```

## 🎯 **MOST LIKELY SOLUTION:**

Try **Fix #3** (enhanced web.config) first - this handles static files explicitly and usually resolves the issue.

**What happens when you try to access the CSS directly in your browser?** (e.g., `http://your-server/css/site.css`) 🔍