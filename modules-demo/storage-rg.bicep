// =============================================================================
// storage-rg.bicep - create 2 resource groups, each with its own storage account
// =============================================================================
//
// This is a SUBSCRIPTION-level deployment (see targetScope below), so it can
// create the resource groups itself - no need to run 'az group create' first.
//
// Both modules reuse the same file: modules/storage.bicep
//
// DEPLOY (from the modules-demo folder)
//   az deployment sub create --location australiaeast --template-file storage-rg.bicep
//
//   Note: --location here is only where Azure stores the deployment record;
//   the resources use the 'location' parameter below.
//
// CLEAN UP
//   az group delete --name rg-storage-1 --yes
//   az group delete --name rg-storage-2 --yes
// =============================================================================

targetScope = 'subscription'

@description('Location for the resource groups and storage accounts.')
param location string = 'australiaeast'

@description('Name of the first resource group.')
param rg1Name string = 'rg-storage-1'

@description('Name of the second resource group.')
param rg2Name string = 'rg-storage-2'

// --- Resource groups --------------------------------------------------------

resource rg1 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rg1Name
  location: location
}

resource rg2 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rg2Name
  location: location
}

// --- Module 1: storage account in resource group 1 --------------------------

module storage1 'modules/storage.bicep' = {
  name: 'storage1Deploy'
  scope: rg1                     // <- deploy this module into rg1
  params: {
    storageAccountName: 'st1${uniqueString(rg1.id)}'
    location: location
  }
}

// --- Module 2: storage account in resource group 2 --------------------------

module storage2 'modules/storage.bicep' = {
  name: 'storage2Deploy'
  scope: rg2                     // <- deploy this module into rg2
  params: {
    storageAccountName: 'st2${uniqueString(rg2.id)}'
    location: location
  }
}

output storageAccount1 string = storage1.outputs.storageAccountName
output storageAccount2 string = storage2.outputs.storageAccountName
