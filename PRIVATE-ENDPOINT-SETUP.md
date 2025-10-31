# Private Endpoint Configuration for Azure SQL Database

## Overview

This document describes the infrastructure changes implemented to enable **private connectivity** between Azure App Service and Azure SQL Database while maintaining public Internet access to the application.

## Architecture Changes

### Before (Public Access)
```
Internet ? App Service ? Public SQL Server Endpoint ? SQL Database
                         ? Blocked by policy
```

### After (Private Endpoint)
```
Internet ? App Service ? VNet Integration ? Private Endpoint ? SQL Database
           (Public)      (Private Network)   (Private IP)     (No Public Access)
```

## Components Added

### 1. Virtual Network (VNet)
**Resource**: `vnet-{resourceToken}`
- **Address Space**: `10.0.0.0/16`
- **Subnets**:
  - **App Service Integration Subnet**: `10.0.0.0/24`
    - Delegated to `Microsoft.Web/serverFarms`
    - Allows App Service to route traffic through VNet
  - **Private Endpoint Subnet**: `10.0.1.0/24`
    - Hosts the SQL Server private endpoint

### 2. Private Endpoint for SQL Server
**Resource**: `pe-sql-{resourceToken}`
- **Location**: Private Endpoint Subnet (`10.0.1.0/24`)
- **Target**: Azure SQL Server
- **Group ID**: `sqlServer`
- **Behavior**: Creates a private IP address for SQL Server within the VNet

### 3. Private DNS Zone
**Resource**: `privatelink.database.windows.net`
- **Purpose**: Resolves SQL Server FQDN to private IP address
- **VNet Link**: Connected to the VNet for DNS resolution
- **DNS Zone Group**: Automatically registers private endpoint IP

### 4. App Service VNet Integration
**Changes to App Service**:
- **VNet Integration**: Connected to App Service Integration Subnet
- **Route All Traffic**: `WEBSITE_VNET_ROUTE_ALL=1`
- **Custom DNS Server**: `168.63.129.16` (Azure DNS)
- **Behavior**: All outbound traffic from App Service routes through VNet

### 5. SQL Server Configuration
**Changes to SQL Server**:
- **Public Network Access**: `Disabled` (changed from `Enabled`)
- **Firewall Rules**: Removed (not needed with private endpoint)
- **Access Method**: Only through private endpoint

## Security Benefits

? **No Public SQL Exposure**: SQL Server is not accessible from the Internet  
? **Compliance**: Meets organizational policy for disabled public access  
? **Network Isolation**: Traffic stays within Azure backbone  
? **DNS Security**: Private DNS zone prevents DNS spoofing  
? **Internet Access Maintained**: App Service remains publicly accessible  

## Network Flow

### Inbound (Internet Users ? App Service)
```
Internet User
    ? HTTPS (443)
Azure App Service (Public IP)
    ? Application Processing
```
**Status**: ? **Public access maintained**

### Outbound (App Service ? SQL Database)
```
App Service
    ? VNet Integration Subnet (10.0.0.0/24)
Private DNS Resolution (168.63.129.16)
    ? Resolves: azsql{token}.database.windows.net ? 10.0.1.x
Private Endpoint (10.0.1.x in Private Endpoint Subnet)
    ? Private Link
SQL Database (No Public IP)
```
**Status**: ? **Private connectivity only**

## Deployment Steps

### Option 1: Using Azure Developer CLI (Recommended)

```bash
# Ensure you're in the project root directory
cd C:\scratch\kevs-app2-mod-appsvc

# Deploy the updated infrastructure
azd up

# This will:
# 1. Provision the VNet with subnets
# 2. Create the private endpoint for SQL Server
# 3. Configure the private DNS zone
# 4. Enable VNet integration on App Service
# 5. Disable public access on SQL Server
# 6. Deploy your application
```

### Option 2: Manual Deployment

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "00a1ec3b-475a-4c51-b020-d74c012c9c0f"

# Deploy the infrastructure
az deployment sub create \
  --location eastus2 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --name kevs-inventory-private-endpoint

# Deploy the application
dotnet publish -c Release
az webapp deploy \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4 \
  --src-path ./bin/Release/net8.0/publish
```

## Validation Steps

### 1. Verify VNet Integration
```bash
az webapp vnet-integration list \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4
```
**Expected**: Should show subnet `appservice-integration-subnet`

### 2. Verify Private Endpoint
```bash
az network private-endpoint list \
  --resource-group kevsapp-rg1 \
  --output table
```
**Expected**: Should show `pe-sql-{resourceToken}` with connection state `Approved`

### 3. Verify SQL Server Public Access
```bash
az sql server show \
  --resource-group kevsapp-rg1 \
  --name azsqlfhkhh3ufmzzq4 \
  --query "publicNetworkAccess" \
  --output tsv
```
**Expected**: `Disabled`

### 4. Verify Private DNS Zone
```bash
az network private-dns zone list \
  --resource-group kevsapp-rg1 \
  --output table
```
**Expected**: Should show `privatelink.database.windows.net` linked to VNet

### 5. Test Application Connectivity
```bash
# Access your application
curl https://azappfhkhh3ufmzzq4.azurewebsites.net

# Check App Service logs for SQL connection success
az webapp log tail \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4
```
**Expected**: Application loads successfully and connects to database

### 6. Verify SQL Connection from App Service Console
```bash
# Open App Service console (Kudu)
https://azappfhkhh3ufmzzq4.scm.azurewebsites.net/DebugConsole

# In console, run:
nslookup azsqlfhkhh3ufmzzq4.database.windows.net
```
**Expected**: Should resolve to private IP (`10.0.1.x`), not public IP

## Troubleshooting

### Issue: App Service Can't Connect to SQL Database

**Symptoms**: HTTP 500 errors, connection timeout errors

**Solutions**:

1. **Check VNet Integration**:
   ```bash
   az webapp show \
     --resource-group kevsapp-rg1 \
     --name azappfhkhh3ufmzzq4 \
     --query "virtualNetworkSubnetId"
   ```
   Should return the subnet ID.

2. **Check Private Endpoint Connection**:
   ```bash
   az network private-endpoint show \
     --resource-group kevsapp-rg1 \
     --name pe-sql-{resourceToken} \
     --query "privateLinkServiceConnections[0].privateLinkServiceConnectionState.status"
   ```
   Should return `Approved`.

3. **Check DNS Resolution**:
   - Go to App Service ? Console (Kudu)
   - Run: `nslookup azsqlfhkhh3ufmzzq4.database.windows.net`
   - Should resolve to `10.0.1.x` (private IP)

4. **Check App Settings**:
   ```bash
   az webapp config appsettings list \
     --resource-group kevsapp-rg1 \
     --name azappfhkhh3ufmzzq4 \
     --query "[?name=='WEBSITE_DNS_SERVER' || name=='WEBSITE_VNET_ROUTE_ALL']"
   ```
   Should show:
   - `WEBSITE_DNS_SERVER`: `168.63.129.16`
   - `WEBSITE_VNET_ROUTE_ALL`: `1`

### Issue: Application is Inaccessible from Internet

**This should NOT happen** - App Service remains publicly accessible.

If you experience this, verify:
```bash
az webapp show \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4 \
  --query "httpsOnly"
```
Should return `true`.

### Issue: Slow DNS Resolution

**Solution**: Restart the App Service to refresh DNS cache:
```bash
az webapp restart \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4
```

## Cost Implications

Additional costs for private endpoint setup:

| Resource | Estimated Monthly Cost (East US 2) |
|----------|-----------------------------------|
| Private Endpoint | ~$7.20 (0.01/hour) |
| Private DNS Zone | ~$0.50 |
| VNet | Free (data transfer charges apply) |
| **Total Additional Cost** | **~$7.70/month** |

**Note**: Basic tier App Service Plan does not support VNet integration. You may need to upgrade to **Standard (S1)** or higher.

### Updated Cost Estimate with Standard Tier

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| App Service Plan (S1) | ~$74/month (was B1 ~$13) |
| Private Endpoint | ~$7.20/month |
| Private DNS Zone | ~$0.50/month |
| **Additional Cost** | **~$68.70/month** |

## SKU Upgrade Requirement

?? **IMPORTANT**: VNet integration requires **Standard (S1)** or higher App Service Plan.

### Upgrade Command
```bash
az appservice plan update \
  --resource-group kevsapp-rg1 \
  --name azplanfhkhh3ufmzzq4 \
  --sku S1
```

Or update in `infra/core/host/appservice.bicep`:
```bicep
sku: {
  name: 'S1'      // Changed from 'B1'
  tier: 'Standard' // Changed from 'Basic'
  size: 'S1'
  family: 'S'
  capacity: 1
}
```

## Infrastructure Files Modified

1. **New Files**:
   - `infra/core/network/vnet.bicep` - Virtual Network with subnets
   - `infra/core/network/private-endpoint.bicep` - Private Endpoint module
   - `infra/core/network/private-dns-zone.bicep` - Private DNS Zone module

2. **Modified Files**:
   - `infra/main.bicep` - Added VNet, Private Endpoint, and DNS orchestration
   - `infra/core/database/sqlserver.bicep` - Disabled public access, removed firewall rules
   - `infra/core/host/appservice.bicep` - Added VNet integration and DNS settings

## Rollback Plan

If you need to revert to public access:

1. **Re-enable SQL Public Access**:
   ```bash
   az sql server update \
     --resource-group kevsapp-rg1 \
     --name azsqlfhkhh3ufmzzq4 \
     --set publicNetworkAccess=Enabled
   ```

2. **Add Firewall Rule**:
   ```bash
   az sql server firewall-rule create \
     --resource-group kevsapp-rg1 \
     --server azsqlfhkhh3ufmzzq4 \
     --name AllowAzureServices \
     --start-ip-address 0.0.0.0 \
     --end-ip-address 0.0.0.0
   ```

3. **Remove VNet Integration** (optional):
   ```bash
   az webapp vnet-integration remove \
     --resource-group kevsapp-rg1 \
     --name azappfhkhh3ufmzzq4
   ```

## References

- [Azure Private Endpoint Documentation](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [App Service VNet Integration](https://learn.microsoft.com/azure/app-service/overview-vnet-integration)
- [Azure SQL Private Link](https://learn.microsoft.com/azure/azure-sql/database/private-endpoint-overview)
- [Azure Private DNS Zones](https://learn.microsoft.com/azure/dns/private-dns-overview)

## Summary

? **App Service**: Publicly accessible from Internet  
? **SQL Database**: Accessible only via private endpoint  
? **Network Traffic**: App Service ? VNet ? Private Endpoint ? SQL Database  
? **DNS Resolution**: Private DNS zone resolves SQL FQDN to private IP  
? **Compliance**: Public network access disabled on SQL Server  
? **Security**: Traffic never leaves Azure backbone  

Your application now meets organizational security policies while maintaining public accessibility! ??
