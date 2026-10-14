
// HOW TO DEPLOY (Azure CLI)
//   1. Log in and pick your subscription:
//        az login
//        az account set --subscription "<subscription name or id>"
//
//   2. Create a resource group (skip if you already have one):
//        az group create --name rg-storage-demo --location australiaeast
//
//   3. (Optional) Preview what will be created:
//        az deployment group what-if --resource-group rg-storage-demo --template-file storage.bicep
//
//   4. Deploy:
//        az deployment group create --resource-group rg-storage-demo --template-file storage.bicep
//
//      Override parameters if you want, e.g.:
//        az deployment group create --resource-group rg-storage-demo --template-file storage.bicep \
//          --parameters accessTier=Hot containerName=backups
//
//   5. Check it:
//        az storage account list --resource-group rg-storage-demo --output table
//
// HOW TO CLEAN UP (stops all charges)
//        az group delete --name rg-storage-demo --yes --no-wait
//
// =============================================================================

@description('Storage account name: 3-24 chars, lowercase letters and numbers only, globally unique. Defaults to a unique generated name.')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('Redundancy SKU. Standard_LRS is the cheapest.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
])
param skuName string = 'Standard_LRS'

@description('Default blob access tier. Cool is cheaper to store, Hot is cheaper to access.')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Cool'

@description('Name of the blob container to create.')
param containerName string = 'data'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    accessTier: accessTier
    // Basic security settings
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
