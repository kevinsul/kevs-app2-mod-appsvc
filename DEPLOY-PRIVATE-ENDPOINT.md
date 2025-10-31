# Quick Deployment Guide - Private Endpoint for Existing Infrastructure

## Your Current Environment

- **Resource Group**: `kevsapp-rg1` (East US 2)
- **App Service**: `azappfhkhh3ufmzzq4`
- **SQL Server**: `azsqlfhkhh3ufmzzq4`
- **SQL Database**: `InventoryDB`
- **Key Vault**: `azkvfhkhh3ufmzzq4`

## ?? Important Pre-Deployment Notes

1. **Downtime Expected**: ~5-10 minutes during VNet integration and SQL reconfiguration
2. **SKU Upgrade**: App Service Plan will upgrade from **B1 ($13/month)** to **S1 ($74/month)**
3. **Additional Costs**: Private Endpoint adds ~$7.70/month
4. **Total Cost Increase**: ~$68.70/month

## ?? Deployment Steps

### Step 1: Review Changes

Review the files that have been modified:

```bash
# Check git status
git status

# Review modified files
git diff infra/main.bicep
git diff infra/core/database/sqlserver.bicep
git diff infra/core/host/appservice.bicep
```

**New files created**:
- `infra/core/network/vnet.bicep`
- `infra/core/network/private-endpoint.bicep`
- `infra/core/network/private-dns-zone.bicep`
- `PRIVATE-ENDPOINT-SETUP.md`

### Step 2: Commit Changes

```bash
git add .
git commit -m "Add private endpoint configuration for Azure SQL Database"
git push origin main
```

### Step 3: Deploy Infrastructure

**Option A: Using Azure Developer CLI (Recommended)**

```bash
# Navigate to project root
cd C:\scratch\kevs-app2-mod-appsvc

# Deploy (this will update existing resources)
azd up

# Follow prompts and confirm changes
```

**Option B: Using Azure CLI**

```bash
# Login
az login

# Set subscription
az account set --subscription "00a1ec3b-475a-4c51-b020-d74c012c9c0f"

# Deploy infrastructure updates
az deployment sub create \
  --location eastus2 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters resourceGroupName=kevsapp-rg1 \
  --name private-endpoint-deployment-$(date +%Y%m%d-%H%M%S)
```

### Step 4: Verify Deployment

#### Check VNet Integration
```bash
az webapp vnet-integration list \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4 \
  --output table
```
? **Expected**: Subnet `appservice-integration-subnet` shown

#### Check Private Endpoint
```bash
az network private-endpoint list \
  --resource-group kevsapp-rg1 \
  --output table
```
? **Expected**: Private endpoint for SQL Server with status `Approved`

#### Check SQL Public Access
```bash
az sql server show \
  --resource-group kevsapp-rg1 \
  --name azsqlfhkhh3ufmzzq4 \
  --query "publicNetworkAccess" \
  --output tsv
```
? **Expected**: `Disabled`

#### Check App Service Plan SKU
```bash
az appservice plan show \
  --resource-group kevsapp-rg1 \
  --name azplanfhkhh3ufmzzq4 \
  --query "sku" \
  --output table
```
? **Expected**: Tier `Standard`, Name `S1`

### Step 5: Test Application

#### Test Web Access (from Internet)
```bash
curl -I https://azappfhkhh3ufmzzq4.azurewebsites.net
```
? **Expected**: HTTP 200 OK

#### Test Database Connectivity
```bash
# Open browser and navigate to your inventory app
https://azappfhkhh3ufmzzq4.azurewebsites.net

# You should see your inventory items
# Try adding a new item to verify write operations
```

#### Check App Logs
```bash
az webapp log tail \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4
```
? **Expected**: No SQL connection errors

### Step 6: Verify DNS Resolution (Optional but Recommended)

```bash
# Open App Service console (Kudu)
# Navigate to: https://azappfhkhh3ufmzzq4.scm.azurewebsites.net/DebugConsole

# In the console, run:
nslookup azsqlfhkhh3ufmzzq4.database.windows.net

# Expected output should show private IP (10.0.1.x), not public IP
```

## ?? Troubleshooting

### Issue 1: Application Can't Connect to Database

**Symptoms**: HTTP 500 errors, "Cannot open database" errors

**Solution**:
```bash
# Restart the app service to refresh DNS cache
az webapp restart \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4

# Wait 2-3 minutes for DNS propagation
# Then test again
```

### Issue 2: VNet Integration Not Working

**Solution**:
```bash
# Check if VNet integration is properly configured
az webapp show \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4 \
  --query "virtualNetworkSubnetId"

# If null, manually add VNet integration
az webapp vnet-integration add \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4 \
  --vnet vnet-{resourceToken} \
  --subnet appservice-integration-subnet
```

### Issue 3: Private Endpoint Connection Pending

**Solution**:
```bash
# Check private endpoint status
az network private-endpoint show \
  --resource-group kevsapp-rg1 \
  --name pe-sql-{resourceToken} \
  --query "privateLinkServiceConnections[0].privateLinkServiceConnectionState"

# If not approved, approve it
az network private-endpoint-connection approve \
  --resource-group kevsapp-rg1 \
  --resource-name azsqlfhkhh3ufmzzq4 \
  --name <connection-name> \
  --type Microsoft.Sql/servers
```

### Issue 4: Deployment Fails - Invalid Bicep Syntax

**Solution**:
```bash
# Validate Bicep template
az bicep build --file infra/main.bicep

# Check for syntax errors
# Fix any reported issues
```

## ?? What Gets Created/Updated

### Created Resources
? Virtual Network with 2 subnets  
? Private Endpoint for SQL Server  
? Private DNS Zone (`privatelink.database.windows.net`)  
? DNS Zone Group (links private endpoint to DNS)  
? VNet Link (links DNS zone to VNet)  

### Updated Resources
?? SQL Server: `publicNetworkAccess` ? `Disabled`  
?? SQL Server: Firewall rule removed  
?? App Service Plan: B1 ? S1 upgrade  
?? App Service: VNet integration enabled  
?? App Service: DNS settings configured  

### Unchanged Resources
? Key Vault  
? Managed Identity  
? Application Insights  
? Log Analytics  
? SQL Database (data preserved)  

## ?? Success Criteria

After deployment, verify:

- [ ] App Service is publicly accessible from Internet
- [ ] Application loads without errors
- [ ] Inventory items display correctly (database connectivity works)
- [ ] Can add/edit/delete inventory items
- [ ] SQL Server shows `publicNetworkAccess: Disabled`
- [ ] Private endpoint shows connection state `Approved`
- [ ] VNet integration is active on App Service
- [ ] DNS resolves SQL Server to private IP (10.0.1.x)
- [ ] No errors in App Service logs

## ?? Rollback Instructions

If something goes wrong and you need to revert:

### Quick Rollback (Emergency)
```bash
# Re-enable SQL public access
az sql server update \
  --resource-group kevsapp-rg1 \
  --name azsqlfhkhh3ufmzzq4 \
  --set publicNetworkAccess=Enabled

# Add Azure services firewall rule
az sql server firewall-rule create \
  --resource-group kevsapp-rg1 \
  --server azsqlfhkhh3ufmzzq4 \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Remove VNet integration
az webapp vnet-integration remove \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4

# Restart app
az webapp restart \
  --resource-group kevsapp-rg1 \
  --name azappfhkhh3ufmzzq4
```

### Full Rollback (Restore Previous State)
```bash
# Checkout previous commit
git log --oneline  # Find commit before private endpoint changes
git checkout <previous-commit-hash>

# Redeploy old infrastructure
azd up
```

## ?? Need Help?

**Common issues and solutions documented in**:
- `PRIVATE-ENDPOINT-SETUP.md` - Detailed architecture and troubleshooting
- `.azure/troubleshooting.md` - General Azure deployment issues

**Azure Support**:
- [Azure Private Link Support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)
- [App Service VNet Integration Docs](https://learn.microsoft.com/azure/app-service/overview-vnet-integration)

## ?? Deployment Checklist

- [ ] Reviewed changes in git diff
- [ ] Committed changes to repository
- [ ] Ran `azd up` successfully
- [ ] Verified VNet integration is active
- [ ] Verified private endpoint is approved
- [ ] Confirmed SQL public access is disabled
- [ ] Tested application from Internet (publicly accessible)
- [ ] Tested database connectivity (CRUD operations work)
- [ ] Checked DNS resolution (private IP returned)
- [ ] Reviewed App Service logs (no errors)
- [ ] Documented any issues encountered
- [ ] Updated team on new infrastructure

**Time to Complete**: 15-30 minutes  
**Risk Level**: Medium (database connectivity changes)  
**Rollback Time**: 5 minutes  

---

**Ready to deploy?** Start with **Step 1** above! ??
