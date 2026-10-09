using 'main.bicep'

param workload = 'kagent'
param environment = 'dev'
param location = 'centralindia'
param openAiLocation = 'swedencentral'   // check model + quota availability
param deployerPrincipalId = '<object-id-of-service-principal>'
param enableMonitoring = false
param deployAcr = false
