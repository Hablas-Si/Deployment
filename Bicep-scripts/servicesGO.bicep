@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'theVNet'
param subnetName string = 'goservicesSubnet'
param dnsRecordName string = 'serviceshostname'
param dnszonename string = 'thednszonename.dk'
param storageAccountName string = 'nostorage'

resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetname
  resource subnet 'subnets@2022-01-01' existing = {
    name: subnetName
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

// --- Create the DevOps container group ---
@description('auktionsHuset services Container Group')
resource auktionsHusetServicesGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'auktionsHusetServicesGroup'
  location: location

  properties: {
    sku: 'Standard'

    containers: [
      {
        name: 'authservice'
        properties: {
          image: 'asbjorndev/auctions_authservice-image:1.0.0'
          ports: [
            {
              port: 3005
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3005'
            }
            {
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'UserServiceUrl'
              value: 'http://services:3010'
            }
            {
              name: 'loki'
              value: 'http://devops:3100'
            }
          
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'userservice'
        properties: {
          image: 'asbjorndev/auction_userservice-image:latest'
          ports: [
            {
              port: 3010
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3010'
            }
            {
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'loki'
              value: 'http://devops:3100'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'catalogservice'
        properties: {
          image: 'chilinhm/catalogservice-image:1.0.0'
          ports: [
            {
              port: 3015
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3015'
            }
            {
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'loki'
              value: 'http://devops:3100'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'auctionservice'
        properties: {
          image: 'cptfaxe/auctionservice-image:1.0.0'
          ports: [
            {
              port: 3020
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3020'
            }
            {
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'ConnectionURI'
              value: 'http://services:3015'
            }
            {
              name: 'loki'
              value: 'http://devops:3100'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'biddingservice'
        properties: {
          image: 'jakobmagni/biddingservice-image:1.0.0'
          ports: [
            {
              port: 3025
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3025'
            }
            {
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'auctionServiceUrl'
              value: 'http://services:3020'
            }
            {
              name: 'loki'
              value: 'http://devops:3100'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'legalservice'
        properties: {
          image: 'asbjorndev/auctions_legalservice-image:latest'
          ports: [
            {
              port: 3030
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '3030'
            }
            {
              //Den value er den originale
              name: 'Address'
              value: 'http://backend:8200/'
            }
            {
              name: 'Token'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'AuctionServiceUrl'
              value: 'http://services:3020'
            }
            {
              name: 'UserServiceUrl'
              value: 'http://services:3010'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'nginx'
        properties: {
          image: 'nginx:latest'
          ports: [
            {
              port: 4000
            } 
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '4000'
            }
          ]
          volumeMounts: [
            {
              name: 'nginx'
              mountPath: '/etc/nginx/' 
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
    ]
    initContainers: []
    restartPolicy: 'Always'
    ipAddress: {
      ports: [
        {
          port: 4000
        }
      ]
      ip: '10.0.3.4'
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'nginx'
        azureFile: {
          shareName: 'storagenginx'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listkeys().keys[0].value
        }
      }
    ]
    subnetIds: [
      {
        id: VNET::subnet.id
      }
    ]
    dnsConfig: {
      nameServers: [
        '10.0.0.10'
        '10.0.0.11'
      ]
      searchDomains: dnszonename
    }
  }
}

// --- Get a reference to the existing DNS zone ---
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

// --- Create the DNS record for the DevOps container group ---
resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: dnsRecordName
  parent: dnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: auktionsHusetServicesGroup.properties.ipAddress.ip
      }
    ]
  }
}

output containerIPAddressFqdn string = auktionsHusetServicesGroup.properties.ipAddress.ip
