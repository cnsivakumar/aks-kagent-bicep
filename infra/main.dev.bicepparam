using 'main.bicep'
param workload = 'kagent'
param environment = 'dev'
param location = 'southeastasia'
param openAiLocation = 'swedencentral'   // check model + quota availability
param deployerPrincipalId = 'f9afdd7b-cf50-4ec0-b4a7-938a69060538'
param enableMonitoring = true
param deployAcr = true
