@description('Which Pricing tier our App Service Plan to')
param skuName string = 'F1'

@description('How many instances of our app service will be scaled out to')
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name that will be used to build associated artifacts')
param appName string = uniqueString(resourceGroup().id)

@description('Repository URL and the branch you want to deploy')
param repositoryUrl string
param branch string = 'main'

var appServicePlanName = toLower('asp-${appName}')
var webSiteName = toLower('wapp-${appName}')
var appInsightName = toLower('appi-${appName}')

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  tags: {
    displayName: 'HostingPlan'
    ProjectName: appName
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: webSiteName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    displayName: 'Website'
    ProjectName: appName
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
}

resource appServiceLogging 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
  }
  dependsOn: [
    appServiceSiteExtension
  ]
}

resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2023-12-01' = {
  parent: appService
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
  dependsOn: [
    appInsights
  ]
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: appService
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
  }
}

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2023-12-01' = { 
  parent: appService
  name: 'web'
  properties: { 
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
}
