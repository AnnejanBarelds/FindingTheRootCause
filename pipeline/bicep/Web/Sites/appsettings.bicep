param siteName string

param appInsightsName string

param settings object

var internalSettings = !empty(appInsightsName) ? {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
} : {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource config 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${siteName}/appsettings'
  properties: union(internalSettings, settings)
}
