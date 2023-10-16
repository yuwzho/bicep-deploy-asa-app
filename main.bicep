@description('Azure Spring Apps Enterprise resource name.')
param name string

@description('Remote URL where can be download as curl')
param remoteURL string

resource buildService 'Microsoft.AppPlatform/Spring/buildServices@2023-03-01-preview' existing = {
  name: '${name}/default'
}

resource builder 'Microsoft.AppPlatform/Spring/buildServices/builders@2023-03-01-preview' existing = {
  name: 'default'
  parent: buildService
}

resource agentPool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2023-03-01-preview' existing = {
  name: 'default'
  parent: buildService
}

module upload 'modules/upload.bicep' = {
  name: 'upload-jar'
  params: {
    name: name
    remoteUrl: remoteURL
  }
}

resource build 'Microsoft.AppPlatform/Spring/buildServices/builds@2023-03-01-preview' = {
  parent: buildService
  name: 'build'
  properties: {
    builder: builder.id
    agentPool: agentPool.id
    relativePath: upload.outputs.relativePath
  }
}

module waitBuild 'modules/waitBuild.bicep' = {
  name: 'wait-build'
  params: {
    buildResultId: build.properties.triggeredBuildResult.id
  }
}

resource app 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: '${name}/app-bicep'
  properties: {
    public: true
  }
}


resource deployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-03-01-preview' = {
  parent: app
  name: 'deployment'
  properties: {
    source: {
      buildResultId: build.properties.triggeredBuildResult.id
      type: 'BuildResult'
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '1'
        memory: '1Gi'
      }
    }
    active: true
  }
  dependsOn: [waitBuild]
}
