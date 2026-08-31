# Importa o Resource Group + ACR que ja existem no Azure (criados anteriormente)
# para o "terraform apply" deste modulo adotar o que ja
# existe em vez de tentar recriar (o que falharia por conflito de nome
# unico/resource ja existente).

import {
  to = azurerm_resource_group.registry
  id = "/subscriptions/1bd9c71c-e648-453c-beaf-e5a084a52d50/resourceGroups/aksterraformgitops"
}

import {
  to = azurerm_container_registry.registry
  id = "/subscriptions/1bd9c71c-e648-453c-beaf-e5a084a52d50/resourceGroups/aksterraformgitops/providers/Microsoft.ContainerRegistry/registries/gbenettiregistry"
}
