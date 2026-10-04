param location string
param aksName string

param githubOrganization string
param githubRepository string
param githubBranch string

resource githubIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-${aksName}-github'
  location: location
}

resource contributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    githubIdentity.id,
    subscription().id,
    'Contributor'
  )

  scope: subscription()

  properties: {
    principalId: githubIdentity.properties.principalId
    principalType: 'ServicePrincipal'

    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c'
    )
  }
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: githubIdentity
  name: 'github-main'

  properties: {
    issuer: 'https://token.actions.githubusercontent.com'

    subject: 'repo:${githubOrganization}/${githubRepository}:ref:refs/heads/${githubBranch}'

    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output clientId string = githubIdentity.properties.clientId
output principalId string = githubIdentity.properties.principalId
