resource app 'Microsoft.AppPlatform/Spring/apps@2023-03-01-preview' = {
  name: 'jeff-std-eus/app-bicep'
  properties: {
    public: true
  }
}

module upload 'modules/upload.bicep' = {
  name: 'upload-jar'
  params: {
    id: app.id
    remoteUrl: 'https://clie2etest.blob.core.windows.net/sample-jar/echo-app-0.0.1-SNAPSHOT.jar'
  }
}

resource deployment 'Microsoft.AppPlatform/Spring/apps/deployments@2023-03-01-preview' = {
  parent: app
  name: 'deployment-4191436'
  properties: {
    source: {
      relativePath: upload.outputs.relativePath
      type: 'Jar'
      runtimeVersion: 'Java_11'
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '1'
        memory: '1Gi'
      }
    }
    active: true
  }
}
