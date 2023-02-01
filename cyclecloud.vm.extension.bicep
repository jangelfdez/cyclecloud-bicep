param location string

param tenantId string

@secure()
@description('Password configured for both the user root of the VM, and administrator of CycleCloud installation')
param adminPassword string
@description('User name configured both as root of the VM, and administrator of CycleCloud installation')
param adminUsername string
@description('SSH Publick Key associated with the administrator user of CycleCloud installation ')
param publicKey string
@description('Name of the existing storage account used by CycleCloud as locker')
param storageAccountName string

param ccVmName string = 'ccVm'
param ccmVmCustomScriptName string = 'ccmVmCustomScript'

resource ccVmCustomScript 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${ccVmName}/${ccmVmCustomScriptName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: 1
    }
    protectedSettings: {
      commandToExecute: 'python3 configure.py --tenantId ${tenantId} --username ${adminUsername} --hostname ${ccVmName} --acceptTerms --useManagedIdentity --password ${adminPassword} --publickey "${publicKey}" --storageAccount ${storageAccountName} --resourceGroup ${resourceGroup().name}'
      fileUris: [
        'https://raw.githubusercontent.com/jangelfdez/cyclecloud-bicep/main/configure.py'
      ]
    }
  }
}
