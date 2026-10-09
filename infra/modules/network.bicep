param name string
param location string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: ['10.10.0.0/16'] }
    subnets: [
      {
        name: 'snet-aks'
        properties: { addressPrefix: '10.10.0.0/22' }
      }
    ]
  }
}

output aksSubnetId string = vnet.properties.subnets[0].id
