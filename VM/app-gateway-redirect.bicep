param applicationGateways_sth_sepms_dev_appgw_name string = 'sth-sepms-dev-appgw'
param virtualNetworks_sth_scus_dv_01_vnet_externalid string = '/subscriptions/51efe03c-14a1-41c3-99f5-2452f128d82f/resourceGroups/sth-network-scus-pd-rg/providers/Microsoft.Network/virtualNetworks/sth-scus-dv-01-vnet'
param publicIPAddresses_sth_sepms_dev_pip_externalid string = '/subscriptions/51efe03c-14a1-41c3-99f5-2452f128d82f/resourceGroups/sth-SEPMS-dev-rg/providers/Microsoft.Network/publicIPAddresses/sth-sepms-dev-pip'

resource applicationGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: applicationGateways_sth_sepms_dev_appgw_name
  location: 'southcentralus'
  tags: {
    environment: 'Dev'
    'external-facing': 'Yes'
    'regulatory-data': 'No'
    'critical-infrastructure': 'No'
    'project-name': 'SEPMS Inspection App'
    owner: 'STH IT Infrastructure'
  }
  zones: ['1', '2', '3']
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/51efe03c-14a1-41c3-99f5-2452f128d82f/resourcegroups/sth-SEPMS-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/sth-SEPMS-dev-id-appcs': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      family: 'Generation_2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${virtualNetworks_sth_scus_dv_01_vnet_externalid}/subnets/sth-scus-dv-appgw-01-snet'
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: '${applicationGateways_sth_sepms_dev_appgw_name}-cert'
        properties: {
          keyVaultSecretId: 'https://sth-sepms-shd-kv.vault.azure.net/secrets/sth-Wildcard'
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_sth_sepms_dev_pip_externalid
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'sepmsdev-bpool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'sth-sepms-dev-quantaservices.msappproxy.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'sepmsDev-bdsettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: 'sth-sepms-dev.thestrongholdcompanies.com'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'sepmsDevListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateways_sth_sepms_dev_appgw_name, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateways_sth_sepms_dev_appgw_name, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateways_sth_sepms_dev_appgw_name, '${applicationGateways_sth_sepms_dev_appgw_name}-cert')
          }
          hostName: 'sepms-dev.thestrongholdcompanies.com'
          requireServerNameIndication: true
        }
      }
      {
        name: 'sth-sepms-dev-Listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateways_sth_sepms_dev_appgw_name, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateways_sth_sepms_dev_appgw_name, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateways_sth_sepms_dev_appgw_name, '${applicationGateways_sth_sepms_dev_appgw_name}-cert')
          }
          hostName: 'sth-sepms-dev.thestrongholdcompanies.com'
          requireServerNameIndication: true
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'sepmsdev-rtrule'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateways_sth_sepms_dev_appgw_name, 'sepmsDevListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateways_sth_sepms_dev_appgw_name, 'sepmsdev-bpool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateways_sth_sepms_dev_appgw_name, 'sepmsDev-bdsettings')
          }
        }
      }
      {
        name: 'sth-sepms-dev-rtrule'
        properties: {
          ruleType: 'Basic'
          priority: 2
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateways_sth_sepms_dev_appgw_name, 'sth-sepms-dev-Listener')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGateways_sth_sepms_dev_appgw_name, 'sth-sepms-dev-rtrule')
          }
        }
      }
    ]
    probes: [
      {
        name: 'sepmsDev-bdsettings75998b19-c4aa-4b10-92ce-97cbad7cb03_'
        properties: {
          protocol: 'Https'
          host: 'sth-sepms-dev.thestrongholdcompanies.com'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: ['200-399']
          }
        }
      }
    ]
    redirectConfigurations: [
      {
        name: 'sth-sepms-dev-rtrule'
        properties: {
          redirectType: 'Temporary'
          targetUrl: 'https://sepms-dev.thestrongholdcompanies.com'
          includePath: true
          includeQueryString: true
        }
      }
    ]
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
  }
}
