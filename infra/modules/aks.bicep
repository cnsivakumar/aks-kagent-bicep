param location string
param aksName string
param acrId string
param kubernetesVersion string
param nodeVmSize string
param nodeCount int

resource aks 'Microsoft.ContainerService/managedClusters@2025-08-01' = {
  name: aksName
  location: location

  identity: {
    type: 'SystemAssigned'
  }

  sku: {
    name: 'Base'
    tier: 'Free'
  }

  properties: {
    kubernetesVersion: kubernetesVersion

    dnsPrefix: '${aksName}-dns'

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }

      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
    }

    agentPoolProfiles: [
      {
        name: 'system'
        count: nodeCount
        vmSize: nodeVmSize

        mode: 'System'

        osType: 'Linux'
        osSKU: 'AzureLinux'

        type: 'VirtualMachineScaleSets'

        enableAutoScaling: true
        minCount: 3
        maxCount: 6

        maxPods: 50

        osDiskSizeGB: 128
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'

      networkPolicy: 'cilium'

      loadBalancerSku: 'standard'

      outboundType: 'loadBalancer'

      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }

    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true

        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }

      azurepolicy: {
        enabled: true
      }
    }

    omsAgent: {
      enabled: true

      config: {
        logAnalyticsWorkspaceResourceID: resourceId(
          'Microsoft.OperationalInsights/workspaces',
          'law-${aksName}'
        )
      }
    }

    autoUpgradeProfile: {
      upgradeChannel: 'stable'
      nodeOSUpgradeChannel: 'NodeImage'
    }
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${aksName}'
  location: location

  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01-preview' existing = {
  id: acrId
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aks.id, 'AcrPull')

  scope: acr

  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'

    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
  }
}

output resourceId string = aks.id

output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerUrl
