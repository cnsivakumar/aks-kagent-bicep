targetScope = 'resourceGroup'

param workload string = 'kagent'

@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

param location string = resourceGroup().location
param openAiLocation string = location
param kubernetesVersion string = ''

// ---- cost levers (dev defaults) ----
@description('Burstable 2 vCPU / 8 GB. Verify availability: az vm list-skus -l <region> --size Standard_B2s_v2')
param systemNodeVmSize string = 'Standard_D2ls_v6'
param systemNodeMinCount int = 1
param systemNodeMaxCount int = 2
@description('Container Insights ingestion is the usual surprise bill. Off for dev.')
param enableMonitoring bool = false
@description('ACR is not needed unless you build custom agent/tool images. kagent pulls from ghcr.io.')
param deployAcr bool = false

param deployerPrincipalId string

param openAiModelName string = 'gpt-4.1-mini'
param openAiModelVersion string = '2025-04-14'
@description('Thousands of tokens/min. Standard is pay-per-token; a low cap also limits runaway spend.')
param openAiCapacity int = 10

param tags object = {
  workload: workload
  environment: environment
  managedBy: 'bicep'
}

var suffix = '${workload}-${environment}'
var uniq = take(uniqueString(resourceGroup().id), 6)

module monitoring 'modules/monitoring.bicep' = if (enableMonitoring) {
  name: 'monitoring'
  params: {
    name: 'log-${suffix}'
    location: location
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    name: 'vnet-${suffix}'
    location: location
    tags: tags
  }
}

module acr 'modules/acr.bicep' = if (deployAcr) {
  name: 'acr'
  params: {
    name: 'acr${workload}${environment}${uniq}'
    location: location
    tags: tags
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks'
  params: {
    name: 'aks-${suffix}'
    location: location
    tags: tags
    subnetId: network.outputs.aksSubnetId
    logAnalyticsId: enableMonitoring ? monitoring!.outputs.workspaceId : ''
    kubernetesVersion: kubernetesVersion
    nodeVmSize: systemNodeVmSize
    nodeMinCount: systemNodeMinCount
    nodeMaxCount: systemNodeMaxCount
  }
}

module openai 'modules/openai.bicep' = {
  name: 'openai'
  params: {
    name: 'oai-${suffix}-${uniq}'
    location: openAiLocation
    tags: tags
    modelName: openAiModelName
    modelVersion: openAiModelVersion
    capacity: openAiCapacity
  }
}

module roles 'modules/roles.bicep' = {
  name: 'roles'
  params: {
    aksName: aks.outputs.name
    acrName: deployAcr ? acr!.outputs.name : ''
    openAiName: openai.outputs.name
    kubeletObjectId: aks.outputs.kubeletObjectId
    deployerPrincipalId: deployerPrincipalId
  }
}

output aksName string = aks.outputs.name
output openAiName string = openai.outputs.name
output openAiEndpoint string = openai.outputs.endpoint
output openAiDeployment string = openai.outputs.deploymentName
