param location string = 'southcentralus'
param adminUsername string = 'admin_lcl'
param adminPassword string = 'Baghdad123' // For security, use Azure Key Vault in production

var vmName = 'STHPJETRPT01'
var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-os'

// Fully qualified subnet ID (in another resource group)
var subnetId = '/subscriptions/51efe03c-14a1-41c3-99f5-2452f128d82f/resourceGroups/sth-network-scus-pd-rg/providers/Microsoft.Network/virtualNetworks/sth-scus-pd-01-vnet/subnets/sth-scus-exp-01-snet'

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    Application: 'Jet'
    environment: 'Prod'
    Location: 'US South Central'
    'Operating System': 'Windows Server 2022 Datacenter'
    OpU: 'Stronghold'
  }
}
