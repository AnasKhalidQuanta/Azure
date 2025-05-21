param location string = 'southcentralus'
param adminUsername string = 'admin_lcl'
param adminPassword string = 'Test123' // For security, use Azure Key Vault in production

var vmName = 'STHPSQLSOXN02'
var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-os'
var dataDisk1Name = '${vmName}-Data'
var dataDisk2Name = '${vmName}-Logs'
var dataDisk3Name = '${vmName}-TempDB'

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
      vmSize: 'Standard_E8s_v3'
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
      dataDisks: [
        {
          lun: 0
          name: dataDisk1Name
          createOption: 'Empty'
          diskSizeGB: 1300
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        {
          lun: 1
          name: dataDisk2Name
          createOption: 'Empty'
          diskSizeGB: 600
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        {
          lun: 2
          name: dataDisk3Name
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
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
    Application: 'MS Dynamics BC 22 SQL'
    environment: 'Prod'
    Location: 'US South Central'
    'Operating System': 'Windows Server 2022 Datacenter/SQL server 2022'
    OpU: 'Stronghold'
  }
}
