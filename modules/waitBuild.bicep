@description('Build result resource id')
param buildResultId string

@description('Where to run the deployment script')
param location string = resourceGroup().location

@description('Azure RoleId that are required for the DeploymentScript resource to read build result')
param rbacRoleNeeded string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader is needed to require build result

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-springapps-wait-build'

@description('For an existing Managed Identity, the Subscription Id it is located in')
param existingManagedIdentitySubId string = subscription().subscriptionId

@description('For an existing Managed Identity, the Resource Group it is located in')
param existingManagedIdentityResourceGroupName string = resourceGroup().name

resource newDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (!useExistingManagedIdentity) {
  name: managedIdentityName
  location: location
}

resource existingDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = if (useExistingManagedIdentity ) {
  name: managedIdentityName
  scope: resourceGroup(existingManagedIdentitySubId, existingManagedIdentityResourceGroupName)
}

resource result 'Microsoft.AppPlatform/Spring/buildServices/builds/results@2023-03-01-preview' existing = {
  name: '${split(buildResultId, '/')[8]}/${split(buildResultId, '/')[10]}/${split(buildResultId, '/')[12]}/${split(buildResultId, '/')[14]}'
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(result.id, rbacRoleNeeded, useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id)
  scope: result
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: useExistingManagedIdentity ? existingDepScriptId.properties.principalId : newDepScriptId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource waitBuildFinish 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: uniqueString('waitBuild')
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id}': {}
    }
  }
  dependsOn: [rbac]
  properties: {
    timeout: 'PT10M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    azCliVersion: '2.51.0'
    environmentVariables: [
      {
        name: 'resource_id'
        value: buildResultId
      }
    ]
    scriptContent: loadTextContent('build.sh')
  }
}
