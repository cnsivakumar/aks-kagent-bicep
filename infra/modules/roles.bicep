param aksName string
param acrName string
param openAiName string
param kubeletObjectId string
param deployerPrincipalId string

var roleIds = {
  acrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  aksClusterUser: '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'
  aksRbacClusterAdmin: 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
  cognitiveServicesContributor: '25fbc0a9-bd7c-42a3-aa1a-3b75d68dc3bc'
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' existing = { name: aksName }
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = { name: acrName }
resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = { name: openAiName }

// Nodes pull custom agent/tool images from ACR
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, kubeletObjectId, roleIds.acrPull)
  scope: acr
  properties: {
    principalId: kubeletObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.acrPull)
  }
}

// Pipeline identity: fetch kubeconfig + install Helm charts, CRDs and RBAC
resource pipelineClusterUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, deployerPrincipalId, roleIds.aksClusterUser)
  scope: aks
  properties: {
    principalId: deployerPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.aksClusterUser)
  }
}

resource pipelineClusterAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, deployerPrincipalId, roleIds.aksRbacClusterAdmin)
  scope: aks
  properties: {
    principalId: deployerPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.aksRbacClusterAdmin)
  }
}

// Pipeline identity: read the OpenAI key at deploy time
resource pipelineOpenAi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openai.id, deployerPrincipalId, roleIds.cognitiveServicesContributor)
  scope: openai
  properties: {
    principalId: deployerPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIds.cognitiveServicesContributor)
  }
}
