// =============================================================================
// main.bicep       - create 2 resource groups, each with its own storage account,
//                    plus an app registration and a Linux App Service in rg1
// =============================================================================
//
// This is a SUBSCRIPTION-level deployment (see targetScope below), so it can
// create the resource groups itself - no need to run 'az group create' first.
//
// Modules:
//   modules/rg1.bicep      -> storage account + app registration + Linux
//                             App Service that signs users in via the app
//                             registration (into rg1)
//   modules/rg2.bicep      -> storage account (into rg2)
//
// The app registration (in modules/rg1.bicep) uses the Microsoft Graph Bicep
// extension, set up in bicepconfig.json. Its deployment is recorded in rg1,
// but the app itself lives in Microsoft Entra ID, not in the resource group.
// You need permission to register apps in your tenant.
//
// DEPLOY (from the modules-demo folder)
//   az deployment sub create --location australiaeast --template-file main.bicep
//
//   Note: --location here is only where Azure stores the deployment record;
//   the resources use the 'location' parameter below.
//
// CLEAN UP
//   az group delete --name rg-storage-1 --yes
//   az group delete --name rg-storage-2 --yes
//   az ad app delete --id <appId output>   (deleting rg1 does NOT remove the app)
// =============================================================================

targetScope = 'subscription'

@description('Location for the resource groups and storage accounts.')
param location string = 'australiaeast'

@description('Name of the first resource group.')
param rg1Name string = 'rg-storage-1'

@description('Name of the second resource group.')
param rg2Name string = 'rg-storage-2'

@description('Display name of the app registration.')
param appName string = 'demo-app-registration'

// --- Resource groups --------------------------------------------------------

resource rg1 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rg1Name
  location: location
}

resource rg2 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rg2Name
  location: location
}

// --- Module 1: storage + app registration + App Service in resource group 1

module rg1Resources 'modules/rg1.bicep' = {
  name: 'rg1Deploy'
  scope: rg1                     // <- deploy this module into rg1
  params: {
    storageAccountName: 'st1${uniqueString(rg1.id)}'
    location: location
    appName: appName
  }
}

// --- Module 2: storage account in resource group 2 --------------------------

module rg2Resources 'modules/rg2.bicep' = {
  name: 'rg2Deploy'
  scope: rg2                     // <- deploy this module into rg2
  params: {
    storageAccountName: 'st2${uniqueString(rg2.id)}'
    location: location
  }
}

// output storageAccount1 string = rg1Resources.outputs.storageAccountName
// output storageAccount2 string = rg2Resources.outputs.storageAccountName
// output appId string = rg1Resources.outputs.appId
// output webAppUrl string = rg1Resources.outputs.webAppUrl
