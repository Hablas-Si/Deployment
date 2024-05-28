@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'goauctionsVNet'
param subnetName string = 'goDevopsSubnet'
param storageAccountName string = 'storageAccount'
param dnsRecordName string = 'backendhostname'
param dnszonename string = 'thednszonename.dk'

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
        name: 'rabbitmq'
        properties: {
          image: 'rabbitmq:management'
          // command: ['tail', '-f', '/dev/null']
          ports: [
            {
              port: 15672
            }
            {
              port: 5672
            }
          ]
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('1.0')
            }
          }
          volumeMounts: [
            {
              name: 'msgqueue'
              mountPath: '/var/lib/rabbitmq'
            }
          ]
        }
      }
      {
        name: 'vault'
        properties: {
          image: 'hashicorp/vault:latest'
          command: ['vault', 'server', '-config=/vault/config/config.hcl']
          ports: [
            {
              port: 8201
            }
          ]
          environmentVariables: [
            {
              name: 'VAULT_TOKEN'
              value: '00000000-0000-0000-0000-000000000000'
            }
            {
              name: 'VAULT_ADDR'
              value: 'https://0.0.0.0:8201/'
            }
            {
              name: 'VAULT_LOCAL_CONFIG'
              value: '{"listener": [{"tcp":{"address": "0.0.0.0:8201","tls_disable": "0", "tls_cert_file":"/data/cert.pem","tls_key_file":"/data/key.pem"}}],"default_lease_ttl": "168h", "max_lease_ttl": "720h", "ui": true}'
            }
            {
              name: 'VAULT_DEV_ROOT_TOKEN_ID'
              value: '00000000-0000-0000-0000-000000000000'
            }
            // skal resten med her nedenunder?
            {
              name: 'PATH'
              value: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
            }
            {
              name: 'NAME'
              value: 'vault'
            }
            {
              name: 'VERSION'
              value: ''
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
          volumeMounts: [
            {
              name: 'vaultconfig'
              mountPath: '/vault/config'
            }
          ]
        }
      }
    ]
    initContainers: []
    restartPolicy: 'Always'
    ipAddress: {
      ports: [
        {
          port: 15672
        }
        {
          port: 5672
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
        name: 'msgqueue'
        azureFile: {
          shareName: 'storagequeue'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
      {
        name: 'vaultconfig'
        azurefile: {
          sharename: 'storagevault'
          storageaccountname: storageAccount.name
          storageaccountkey: storageAccount.listkeys().keys[0].value
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
