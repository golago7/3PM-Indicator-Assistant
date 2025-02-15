@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param cognitiveServiceName string = 'CognitiveService-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'S0'
])
param sku string = 'S0'

resource cognitiveService 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: cognitiveServiceName
  location: location
  sku: {
    name: sku
  }
  kind: 'CognitiveServices'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: cognitiveService
  name: 'gpt-4o'
  properties: {
    model: {
      name: 'gpt-4o'
      format: 'OpenAI'
      version: '2024-05-13'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  sku: {
    name: 'Standard'
    // capacity: 1
  }
}


resource hub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: '${aiStudioHubName}-${resourceSuffix}'
  location: aiStudioHubLocation
  sku: {
    name: aiStudioSKUName
    tier: aiStudioSKUTier
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiStudioHubName
    storageAccount: storage.id
    keyVault: keyVault.id
    applicationInsights: applicationInsights.id
    containerRegistry: containerRegistry.id
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${aiStudioHubLocation}.api.azureml.ms/discovery'
  }

  resource openAiConnection 'connections@2024-04-01-preview' = {
    name: 'open_ai_connection'
    properties: {
      category: 'AzureOpenAI'
      authType: 'ApiKey'
      isSharedToAll: true
      target: apimService.properties.gatewayUrl
      enforceAccessToDefaultSecretStores: true
      metadata: {
        ApiVersion: '2024-02-01'
        ApiType: 'azure'
      }
      credentials: {
        key: apimSubscription.listSecrets().primaryKey
      }
    }
  }

  resource AISearchConnection 'connections@2024-04-01-preview' = {
    name: 'ai_search_connection'
    properties: {
      category: 'CognitiveSearch'
      authType: 'ApiKey'
      isSharedToAll: true
      target: 'https://${searchServiceName}-${resourceSuffix}.search.windows.net'
      enforceAccessToDefaultSecretStores: true
      metadata: {
        ApiVersion: '2024-02-01'
        ApiType: 'azure'
      }
      credentials: {
        key: searchService.listAdminKeys().primaryKey
      }
    }
  }

}


resource project 'Microsoft.MachineLearningServices/workspaces@2024-07-01-preview' = {
  name: '${aiStudioProjectName}-${resourceSuffix}'
  location: aiStudioHubLocation
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiStudioProjectName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://${aiStudioHubLocation}.api.azureml.ms/discovery'
    hubResourceId: hub.id
  }
}

output cognitiveServiceEndpoint string = cognitiveService.properties.endpoint
