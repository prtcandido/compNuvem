# 1. Definir o provedor (Azure)
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 2. Configurar as funcionalidades do Provedor
provider "azurerm" {
  features {} # Este bloco é obrigatório para a Azure

  # Dados de autenticação do Service Principal
  <<<<< Incluir parâmetros de autenticação do Service Principal >>>>>
}

# 3. Criar o Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = "grupoTeste"
  location = "Brazil South"
}

# 4. Criar o Azure Container Registry (ACR) - Docker Registry Privado
resource "azurerm_container_registry" "acr" {
  name                = "meuregistroprivado" # Nome único globalmente
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # Ativa usuário/senha para facilitar o acesso inicial
}

# # 5. Configurar o Container para ler do ACR
# resource "azurerm_container_group" "container" {
#   name                = "meu-app-privado"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   os_type             = "Linux"
#   ip_address_type     = "Public"

#   # Credenciais de acesso ao ACR
#   image_registry_credential {
#     server   = azurerm_container_registry.acr.login_server
#     username = azurerm_container_registry.acr.admin_username
#     password = azurerm_container_registry.acr.admin_password
#   }

#   container {
#     name   = "app-custom"
#     # Note que agora o caminho da imagem aponta para o seu ACR
#     image  = "${azurerm_container_registry.acr.login_server}/viteex1-frontend:v1"
#     cpu    = "0.5"
#     memory = "1.5"

#     ports {
#       port     = 80
#       protocol = "TCP"
#     }
#   }
# }
