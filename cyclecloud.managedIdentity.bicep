targetScope = 'subscription'

param principalId string

//By default, Contributor role at the subscription level is assigned to CycleCloud Server VM managed identity
resource ccVmMiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ccVmMiRoleAssignment')
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
}
