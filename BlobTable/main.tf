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
}

# 3. Criar o Grupo de Recursos
resource "azurerm_resource_group" "rg-teste" {
  name     = "grupoTeste"
  location = "Brazil South"
}

# 4. Criar conta de armazenamento
resource "azurerm_storage_account" "sc" {
  name                     = "prtcandido123" # deve der único dentro da Azure
  resource_group_name      = azurerm_resource_group.rg-teste.name
  location                 = azurerm_resource_group.rg-teste.location
  account_tier             = "Standard" # armazenamento em discos rígidos. Premium - armazenamento em SSD (maior custo)
  account_replication_type = "LRS" # ver em NuvemArquiteturaServico.pdf
}

# 5. Criar um Container (Equivale a pastas para os arquivos)
resource "azurerm_storage_container" "ct" {
  name                  = "cteste1"
  storage_account_name  = azurerm_storage_account.sc.name
  container_access_type = "private"
}

# 6. Criar Table Store
resource "azurerm_storage_table" "tabela" {
  name                 = "tabela123"
  storage_account_name = azurerm_storage_account.sc.name
}