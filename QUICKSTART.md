# Quick Start Guide

## ⚡ Get the Inventory App Running in 5 Minutes

### Prerequisites Check
- ✅ .NET 8.0 SDK installed
- ✅ SQL Server (any version 2014+) accessible
- ✅ Network connectivity for NuGet packages

### 🚀 Quick Setup Steps

#### 1. Restore Packages
```bash
dotnet restore
```

#### 2. Update Database Connection
Edit `appsettings.json` and replace `YOUR_DATABASE_SERVER` with your SQL Server name:
```json
"DefaultConnection": "Server=YOUR_DATABASE_SERVER;Database=InventoryDB;Trusted_Connection=true;TrustServerCertificate=true;"
```

#### 3. Create Database
**Option A - Automatic (EF Migrations):**
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Option B - Manual (SQL Script):**
- Open `Scripts/DatabaseSetup.sql` in SQL Server Management Studio
- Execute the script on your SQL Server

#### 4. Run the Application
```bash
dotnet run
```

#### 5. Open in Browser
Navigate to: `https://localhost:5001` or `http://localhost:5000`

### 🎯 What You'll See
- **Inventory Dashboard**: Clean, professional interface
- **Add Items**: Form to create new inventory items
- **Edit/Delete**: Full CRUD operations
- **Validation**: Real-time input validation
- **Responsive**: Works on desktop, tablet, and mobile

### 🔧 VS Code Integration
- **F5**: Debug the application
- **Ctrl+Shift+P** → "Tasks: Run Task" → Select build/run tasks
- IntelliSense and debugging fully configured

### 📦 Sample Data
The database setup script includes sample data:
- Laptop Computer (LAP-001)
- Wireless Mouse (MSE-001)
- USB-C Hub (HUB-001)
- Monitor (MON-001)
- Keyboard (KBD-001)

### 🚨 Troubleshooting
**Can't restore packages?** Check internet connection and NuGet sources
**Database connection failed?** Verify SQL Server is running and connection string is correct
**Port already in use?** Change ports in `Properties/launchSettings.json`

### 📚 Need More Details?
- See `README.md` for comprehensive documentation
- See `DEPLOYMENT.md` for production IIS deployment
- Check `.github/copilot-instructions.md` for project overview

---
**Ready to deploy to production?** Follow the complete deployment guide in `DEPLOYMENT.md`