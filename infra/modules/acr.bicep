param location string
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01-preview' = {
  name: acrName
  location: location

  sku: {
    name: 'Standard'
  }

  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output resourceId string = acr.id
output acrName string = acr.name
output loginServer string = acr.properties.loginServer
