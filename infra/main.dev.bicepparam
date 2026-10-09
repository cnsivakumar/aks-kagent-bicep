using 'main.bicep'
param workload = 'kagent'
param environment = 'dev'
param location = 'centralindia'
param openAiLocation = 'swedencentral'   // check model + quota availability
param deployerPrincipalId = '1dc300d6-5a8a-4396-903e-de0be2e95881'
param enableMonitoring = false
param deployAcr = false
