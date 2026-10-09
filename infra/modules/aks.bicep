param name string
param location string
param tags object
param subnetId string
param logAnalyticsId string
param kubernetesVersion string
param nodeVmSize string
param nodeMinCount int
param nodeMaxCount int

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: { type: 'SystemAssigned' }
  properties: {
    dnsPrefix: name
    kubernetesVersion: empty(kubernetesVersion) ? null : kubernetesVersion
    // Entra ID only: no static admin kubeconfig, Kubernetes authz via Azure RBAC
    disableLocalAccounts: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: tenant().tenantId
    }
    oidcIssuerProfile: { enabled: true }
    securityProfile: {
      workloadIdentity: { enabled: true }
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkDataplane: 'cilium'
      networkPolicy: 'cilium'
      loadBalancerSku: 'standard'
      serviceCidr: '10.20.0.0/16'
      dnsServiceIP: '10.20.0.10'
    }
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        osType: 'Linux'
        vmSize: nodeVmSize
        vnetSubnetID: subnetId
        enableAutoScaling: true
        count: nodeMinCount
        minCount: nodeMinCount
        maxCount: nodeMaxCount
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsId
          useAADAuth: 'true'
        }
      }
    }
    autoUpgradeProfile: { upgradeChannel: 'patch' }
  }
}

output name string = aks.name
output kubeletObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
