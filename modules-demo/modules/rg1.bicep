// Module: everything for resource group 1
//   - a cheap storage account (Standard_LRS, Cool tier)
//   - a simple Microsoft Entra ID app registration
//   - a simple Linux App Service (plan + web app) that uses the app
//     registration as its identity provider (App Service Authentication)
//
// The app registration uses the Microsoft Graph Bicep extension (configured in
// ../bicepconfig.json). Note: the app lives in Entra ID (the tenant), NOT in
// the resource group - only its deployment record is in rg1.

extension microsoftGraphV1

@minLength(3)
@maxLength(24)
param storageAccountName string
param location string

@description('Display name of the app registration.')
param appName string

@description('Name of the web app. Must be globally unique (it becomes <name>.azurewebsites.net).')
param webAppName string = 'app-${uniqueString(resourceGroup().id)}'

@description('Name of the App Service plan.')
param appServicePlanName string = 'asp-${uniqueString(resourceGroup().id)}'

@description('App Service plan SKU. F1 is free; B1 is the cheapest paid tier.')
@allowed([
  'F1'
  'B1'
])
param appServicePlanSku string = 'F1'

@description('Runtime stack for the Linux web app.')
param linuxFxVersion string = 'NODE|22-lts'

// The web app's default hostname is predictable, so the app registration can
// use it for its redirect URI without waiting for the web app to be created.
var webAppHostName = '${webAppName}.azurewebsites.net'

// --- Storage account --------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Cool'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// --- App registration -------------------------------------------------------

resource app 'Microsoft.Graph/applications@v1.0' = {
  displayName: appName
  uniqueName: appName            // required by Bicep: lets re-deploys update the same app instead of creating a new one
  signInAudience: 'AzureADMyOrg' // single tenant: only users in your directory can sign in
  web: {
    // Where Entra ID sends users back to after they sign in to the web app
    redirectUris: [
      'https://${webAppHostName}/.auth/login/aad/callback'
    ]
    implicitGrantSettings: {
      enableIdTokenIssuance: true // lets App Service sign users in without a client secret
    }
  }
}

// --- Linux App Service ------------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true               // required for Linux plans
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: false            // must be false on the F1 (free) tier
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
}

// App Service Authentication ("Easy Auth"): users must sign in with Entra ID,
// using the app registration above as the identity provider.
resource webAppAuth 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'authsettingsV2'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: app.appId
          openIdIssuer: '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'
        }
      }
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
  }
}

// Values passed back to the parent file
output storageAccountName string = storageAccount.name
output appId string = app.appId  // the "Application (client) ID"
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
