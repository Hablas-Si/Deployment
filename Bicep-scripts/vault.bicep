@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'goauctionsVNet'
param subnetName string = 'goDevopsSubnet'
param storageAccountName string = 'storageAccount'
param dnsRecordName string ='backendhostname'
param dnszonename string='thednszonename.dk'


// --- Get a reference to our existing Virtual Network ---
resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetname
  resource subnet 'subnets@2022-01-01' existing = {
    name: subnetName
  }
}

// --- Get a reference to the existing storage ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

// --- Create the backend container group ---
@description('auktionsHusetBackendGroup')
resource auktionsHusetBackendGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'auktionsHusetBackendGroup'
  location: location
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: 'mongodb'
        properties: {
          image: 'mongo:latest'
          command: [
            'mongod'
            '--dbpath=/data/auktionsdb'
            '--auth'
            '--bind_ip_all'
          ]
          ports: [
            {
              port: 27017
            }
          ]
          environmentVariables: [
            
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
          volumeMounts: [
            {
              name: 'db'
              mountPath: '/data/auktionsdb/'
            }
          ]
        }
      }
      {
        name: 'rabbitmq'
        properties: {
          image: 'rabbitmq:management'
          ports: [
            {
              port: 15672
            }
            {
              port: 5672
            }
          ]
          environmentVariables: [
            {
              name: 'RABBITMQ_DEFAULT_USER'
              value: 'guest'
            }
            {
              name: 'RABBITMQ_DEFAULT_PASS'
              value: 'guest'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('1.0')
            }
          }
          volumeMounts: [
            {
              name: 'msgqueue'
              mountPath: '/var/lib/rabbitmq/mnesia'
            }
          ]
        }
      }
      {
        name: 'vault'
        properties: {
          image: 'hashicorp/vault:latest'
          command: [
            'vault'
            'server'
            '-dev'
          ]
          ports: [
            {
              port: 8201
            }
            {
              port: 8200
            }
          ]
          environmentVariables: [
            {
              name: 'VAULT_ADDR'
              value: 'http://0.0.0.0:8200'
            }
            {
              name: 'VAULT_API_ADDR'
              value: 'http://0.0.0.0:8200'
            }
            {
              name: 'VAULT_DEV_LISTEN_ADDRESS'
              value: '0.0.0.0:8200'
            }
            {
              name: 'VAULT_LOG_LEVEL'
              value: 'debug'
            }
            { 
              name: 'VAULT_LOCAL_CONFIG'
              value: '{"listener": [{"tcp":{"address": "0.0.0.0:8200", "tls_disable": "1", "tls_cert_file":"/vault/config/cert.pem", "tls_key_file":"/vault/config/key.pem"}}], "default_lease_ttl": "168h", "max_lease_ttl": "720h"}, "ui": true}'
            }
            {
              name: 'VAULT_DEV_ROOT_TOKEN_ID'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'VAULT_TOKEN'
              value: '00000000-0000-0000-0000-000000000000'
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('1.0')
            }
          }
          volumeMounts: [
            {
              name: 'vaultdata'
              mountPath: '/vault/'
            }
          ]
        }
      }
    ]
    initContainers: []
    restartPolicy: 'Never'
    ipAddress: {
      ports: [
        {
          port: 27017
        }
        {
          port: 15672
        }
        {
          port: 5672
        }
        {
          port: 8200
        }
        {
          port: 8201
        }
      ]
      ip: '10.0.1.4'
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'db'
        azureFile: {
          shareName: 'storagedata'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
      {
        name: 'msgqueue'
        azureFile: {
          shareName: 'storagequeue'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
      {
        name: 'vaultdata'
        azureFile: {
          shareName: 'storagevault'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
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


// --- Get a reference to the existing DNS Zone ---
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

// --- Create the DNS record for the backend container group ---
resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: dnsRecordName
  parent: dnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: auktionsHusetBackendGroup.properties.ipAddress.ip
      }
    ]
  }
}

output containerIPAddressFqdn string = auktionsHusetBackendGroup.properties.ipAddress.ip
