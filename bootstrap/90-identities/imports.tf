# Importa os recursos do "app de registry" (setup_appRegistration.sh) que ja
# existem no Azure/Entra ID, para o "terraform apply" deste modulo adotar o
# que ja existe em vez de tentar recriar (o que falharia por conflito de nome
# unico / federated credential ja existente).

import {
  to = azuread_application.registry
  id = "/applications/e2206754-fa6b-406b-b268-27f62defa0c8" # app "gh-actions-gbenettiregistry"
}

import {
  to = azuread_service_principal.registry
  id = "2ba6b95c-db2e-4555-81a7-e4ee5c7978cc"
}

import {
  to = azuread_application_federated_identity_credential.registry_branch
  id = "e2206754-fa6b-406b-b268-27f62defa0c8/federatedIdentityCredential/5966d7d3-70c0-4a4a-8213-2e2d71c2252f"
}

import {
  to = azurerm_role_assignment.registry_acr_push
  id = "/subscriptions/1bd9c71c-e648-453c-beaf-e5a084a52d50/resourceGroups/aksterraformgitops/providers/Microsoft.ContainerRegistry/registries/gbenettiregistry/providers/Microsoft.Authorization/roleAssignments/8e38370d-e0d4-46ec-a616-edbf8d60a8a8"
}
