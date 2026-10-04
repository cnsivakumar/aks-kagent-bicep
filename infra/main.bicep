targetScope = 'subscription'

@description('Azure location')
param location string = 'eastus'

@description('Resource group name')
param resourceGroupName string = 'rg-kagent-aks'

@description('AKS cluster name')
param aksName string = 'aks-kagent-demo'

@description('ACR name. Must be globally unique.')
param acrName string = 'kagentacr${uniqueString(subscription().id)}'

@description('GitHub organization/user')
param githubOrganization string

@description('GitHub repository')
param githubRepository string

@description('GitHub branch allowed to deploy')
param githubBranch string = 'main'

@description('Kubernetes version required by current kagent 1.x installation')
param kubernetesVersion string = '1.37'

@description('AKS node VM size')
param nodeVmSize string = 'Standard_D4s_v5'

@description('Initial node count')
param nodeCount int = 3

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
}

module acr './modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: location
    acrName: acrName
  }
}

module aks './modules/aks.bicep' = {
  name: 'aks'
  scope: rg
  params: {
    location: location
    aksName: aksName
    acrId: acr.outputs.resourceId
    kubernetesVersion: kubernetesVersion
    nodeVmSize: nodeVmSize
    nodeCount: nodeCount
  }
}

module githubOidc './modules/github-oidc.bicep' = {
  name: 'github-oidc'
  scope: rg
  params: {
    location: location
    aksName: aksName
    githubOrganization: githubOrganization
    githubRepository: githubRepository
    githubBranch: githubBranch
  }
}

output resourceGroupName string = rg.name
output aksName string = aksName
output acrName string = acr.outputs.acrName
output githubFederatedClientId string = githubOidc.outputs.clientId
