@description('resourceId to retrive upload url.')
param id string

@description('Remote url of the binary to be deployed. It should be able to be downloaded by CURL -o')
param remoteUrl string

@description('Where to run the deployment script')
param location string = resourceGroup().location

@description('Azure RoleId that are required for the DeploymentScript resource to import images')
param rbacRoleNeeded string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor is needed to require upload url

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-springapps-deploy'

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

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(id, rbacRoleNeeded, useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: useExistingManagedIdentity ? existingDepScriptId.properties.principalId : newDepScriptId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: uniqueString('upload')
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
        name: 'source_url'
        value: remoteUrl
      }
      {
        name: 'resource_id'
        value: id
      }
    ]
    scriptContent: loadTextContent('upload.sh')
  }
}

output relativePath string = deploymentScript.properties.outputs.relativePath
