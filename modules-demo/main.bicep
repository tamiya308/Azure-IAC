// =============================================================================
// main.bicep - simple example of a Bicep file that uses 2 modules
// =============================================================================
//
// FILES
//   main.bicep               <- this file (the "parent"); calls the modules
//   modules/network.bicep    <- module 1: a virtual network (free)
//   modules/storage.bicep    <- module 2: a cheap storage account
//
// DEPLOY (from the modules-demo folder)
//   az group create --name rg-modules-demo --location australiaeast
//   az deployment group create --resource-group rg-modules-demo --template-file main.bicep
//
// CLEAN UP
//   az group delete --name rg-modules-demo --yes
// =============================================================================

@description('Short prefix used to name the resources.')
param prefix string = 'demo'

@description('Location for all resources.')
param location string = resourceGroup().location

// Module 1: virtual network
module network 'modules/network.bicep' = {
  name: 'networkDeploy'          // name of this module's deployment (shows in deployment history)
  params: {
    vnetName: '${prefix}-vnet'
    location: location
  }
}

// Module 2: storage account
module storage 'modules/storage.bicep' = {
  name: 'storageDeploy'
  params: {
    storageAccountName: '${prefix}st${uniqueString(resourceGroup().id)}'
    location: location
  }
}

// Outputs from the modules can be read with <module>.outputs.<name>
output vnetId string = network.outputs.vnetId
output storageAccountName string = storage.outputs.storageAccountName
