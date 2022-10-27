// Required configuration parameters

@description('CycleCloud requirements suggest a Virtual Machine with minimum 4vCPUs and 8GB RAM')
param vmSize string = 'Standard_D4s_v5'

@description('Name of an existing Virtual Network where CycleCloud server instance would be deployed ')
param vnetName string
@description('Name of the existing subnet inside the Virtual Network where CyecleCloud server instance would be deployed ')
param subnetName string
@description('Name of the resource group where the virtual network is provisioned. It not provided, the same resource group where the VM is being deployed is considered')
param vnetResourceGroupName string = resourceGroup().name


@secure()
@description('Password configured for both the user root of the VM, and administrator of CycleCloud installation')
param adminPassword string
@description('User name configured both as root of the VM, and administrator of CycleCloud installation')
param adminUsername string


param location string = resourceGroup().location

// Optional deployment customizations
param ccVmName string 
param ccVmPublicIpName string 
param ccVmNicName string 
param ccComputerName string 

resource ccVmVnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
}

resource ccVmSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  parent: ccVmVnet
  name: subnetName
}

resource ccVmPublicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: ccVmPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource ccVmNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: ccVmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: ccVmSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ccVmPublicIp.id
            properties: {
              deleteOption: 'Delete'
            }
          }
        }
      }
    ]
  }
}

resource ccVm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: ccVmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: 'cyclecloud-81'
    publisher: 'azurecyclecloud'
    product: 'azure-cyclecloud'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: ccComputerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'azurecyclecloud'
        offer: 'azure-cyclecloud'
        sku: 'cyclecloud-81'
        version: 'latest'
      }
      osDisk: {
        name: '${ccVmName}-osDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'FromImage'
          caching: 'None'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          writeAcceleratorEnabled: false
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ccVmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output principalId string = ccVm.identity.principalId
