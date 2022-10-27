targetScope = 'subscription'

param location string = 'westeurope'

// Required configuration parameters
@description('Name of the resource group where the CycleCloud server instance would be deployed')
param resourceGroupName string

@description('CycleCloud requirements suggest a Virtual Machine with minimum 4vCPUs and 8GB RAM')
param vmSize string = 'Standard_D4s_v5'

@description('Name of an existing Virtual Network where CycleCloud server instance would be deployed ')
param vnetName string
@description('Name of the existing subnet inside the Virtual Network where CyecleCloud server instance would be deployed ')
param subnetName string
@description('Name of the resource group where the virtual network is provisioned. It not provided, the same resource group where the VM is being deployed is considered')
param vnetResourceGroupName string = resourceGroupName
@description('Name of the existing storage account used by CycleCloud as locker')
param storageAccountName string

param tenantId string

@secure()
@description('Password configured for both the user root of the VM, and administrator of CycleCloud installation')
param adminPassword string
@description('User name configured both as root of the VM, and administrator of CycleCloud installation')
param adminUsername string
@description('SSH Publick Key associated with the administrator user of CycleCloud installation ')
param publicKey string

// Optional deployment customizations
param ccVmName string = 'ccVm'
param ccVmPublicIpName string = 'ccVmPublicIp'
param ccVmNicName string = 'ccVmNic'
param ccComputerName string = 'ccserver'
param ccmVmCustomScriptName string = 'ccmVmCustomScript'

module ccVM 'cyclecloud.vm.bicep' = {
  name: ccVmName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    adminPassword: adminPassword
    adminUsername: adminUsername
    subnetName: subnetName
    vnetName: vnetName
    vmSize: vmSize
    ccComputerName: ccComputerName
    ccVmName: ccVmName
    ccVmPublicIpName: ccVmPublicIpName
    ccVmNicName: ccVmNicName
    vnetResourceGroupName: vnetResourceGroupName
  }
}

module ccManagedIdentity 'cyclecloud.managedIdentity.bicep' = {
  name: guid('ccVmMiRoleAssignment')
  params: {
    principalId: ccVM.outputs.principalId
  }
}

module ccVmCustomScript 'cyclecloud.vm.extension.bicep' = {
  name: ccmVmCustomScriptName
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    ccManagedIdentity
  ]
  params: {
    adminPassword: adminPassword
    adminUsername: adminUsername
    location: location
    publicKey: publicKey
    storageAccountName: storageAccountName
    tenantId: tenantId
    ccmVmCustomScriptName: ccmVmCustomScriptName
    ccVmName: ccVmName
  }

}
