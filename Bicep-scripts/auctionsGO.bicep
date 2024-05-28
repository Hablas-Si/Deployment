@description('Location for all resources.')
param location string = resourceGroup().location

// --- Konfigurerbare parametre ---

@description('Name of virtual network')
var virtualNetworkName = 'goauctionsVNet'

@description('Name of public ip address')
var publicIPAddressName = 'goauctions-public_ip'

@description('Name of the application Gateway')
var applicationGateWayName = 'goauctionsAppGateway'

@description('Name of the DNS zone')
var dnszonename = 'aktionssuperhus.dk'

// har ændret denne værdi
@description('Public Domain name used when accessing gateway from internet')
var publicDomainName = 'aktionssuperhus'

@description('List of file shares to create')
var shareNames = [
  'config'
  'data'
  'images'
  'queue'
  'grafana'
  'vault'
  'nginx-config'
]

// --- Call Bicep submodules ------------------------------

module network 'networkGO.bicep' = {
  name: 'networkModule'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    publicIPAddressName: publicIPAddressName
    publicDomainName: publicDomainName
    dnszonename: dnszonename
  }  
}

module storage 'storageGO.bicep' = {
  name: 'storageModule'
  params: {
    location: location
    sharePrefix: 'storage'
    shareNames: shareNames
  }  
}

module devops 'devopsGO.bicep' = {
  name: 'devopsModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goDevopsSubnet'
    dnsRecordName: 'DEVOPS'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAcountName
  }
}

module backend 'backendGO.bicep' = {
  name: 'backendModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goBackendSubnet'
    dnsRecordName: 'BACKEND'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAcountName
  }
}

// Tilføjet services
module services 'servicesGO.bicep' = {
  name: 'servicesModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goServicesSubnet'
    dnsRecordName: 'SERVICES'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAcountName
  }
}

// --- Create the Application Gateway  ------------------------------

resource applicationGateWay 'Microsoft.Network/applicationGateways@2022-11-01' = {
  name: applicationGateWayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'applicationGatewaySubnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'GrafanaFrontPort'
        properties: {
          port: 3000
        }
      }
      {
        name: 'rabbitmqPort'
        properties: {
          port: 15672
        }
      }
      {
        name: 'authservicePort'
        properties: {
          port: 3005
        }
      }
      {
        name: 'userservicePort'
        properties: {
          port: 3010
        }
      }
      {
        name: 'catalogservicePort'
        properties: {
          port: 3015
        }
      }
      {
        name: 'auctionservicePort'
        properties: {
          port: 3020
        }
      }
      {
        name: 'biddingservicePort'
        properties: {
          port: 3025
        }
      }
      {
        name: 'legalservicePort'
        properties: {
          port: 3030
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'goAuctionsBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backend.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
      {
        name: 'goAuctionsDevopsPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: devops.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
      {
        name: 'goAuctionsServicesPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: services.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'GrafanaHttpSettings'
        properties: {
          port: 3000
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
      {
        name: 'rabbitMQHttpSettings'
        properties: {
          port: 15672
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
      {
        name: 'authserviceSettings'
        properties: {
            port: 3005
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
      {
        name: 'userserviceSettings'
        properties: {
            port: 3010
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
      {
        name: 'catalogserviceSettings'
        properties: {
            port: 3015
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
      {
        name: 'auctionserviceSettings'
        properties: {
            port: 3020
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
      {
        name: 'biddingserviceSettings'
        properties: {
            port: 3025
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
      {
        name: 'legalserviceSettings'
        properties: {
            port: 3030
            protocol: 'Http'
            cookieBasedAffinity: 'Disabled'
            connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
            }
            pickHostNameFromBackendAddress: false
            requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'GrafanaHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'GrafanaFrontPort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'RabbitMQHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'rabbitmqPort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }

      {
        name: 'authserviceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'authservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'userserivceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'userservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'catalogserviceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'catalogservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'auctionserivceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'auctionservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'biddingserviceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'biddingservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
       {
        name: 'legalserviceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'legalservicePort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      
    ]
    requestRoutingRules: [
      {
        name: 'GrafanaRule'
        properties: {
          ruleType: 'Basic'
          priority: 12000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'GrafanaHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsDevopsPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'GrafanaHttpSettings')
          }
        }
      }
      {
        name: 'RabbitMqRule'
        properties: {
          ruleType: 'Basic'
          priority: 11000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'RabbitMQHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'rabbitMQHttpSettings')
          }
        }
      }

      {
        name: 'authserviceRule'
        properties: {
          ruleType: 'Basic'
          priority: 10000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'authserviceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'authseviceSettings')
          }
        }
      }
      {
        name: 'catalogserviceRule'
        properties: {
          ruleType: 'Basic'
          priority: 9000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'catalogserviceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'catalogserviceSettings')
          }
        }
      }
      {
        name: 'auctionserviceRule'
        properties: {
          ruleType: 'Basic'
          priority: 8000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'auctionserviceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'auctionserviceSettings')
          }
        }
      }
      {
        name: 'biddingserviceRule'
        properties: {
          ruleType: 'Basic'
          priority: 7000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'biddingserviceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'biddingserviceSettings')
          }
        }
      }
      {
        name: 'legalserviceRule'
        properties: {
          ruleType: 'Basic'
          priority: 6000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'legalserviceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'legalserviceSettings')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
  dependsOn: [
    network
  ]
}

output vaultIp string = backend.outputs.containerIPAddressFqdn

