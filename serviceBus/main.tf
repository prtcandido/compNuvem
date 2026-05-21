# 1. Definição dos Providers requeridos
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Mantendo compatibilidade com a árvore 3.x estável
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Variáveis para flexibilizar o código
variable "location" {
  type    = string
  default = "Brazil South"
}

variable "project_name" {
  type    = string
  default = "microsservicos"
}

variable "environment" {
  type    = string
  default = "dev"
}

# 3. Criação do Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

# 4. Criação do Service Bus Namespace
# Nota: O SKU 'Standard' é o mínimo recomendado para produção por suportar tópicos, 
# sessões e detecção de duplicidade. O 'Basic' suporta apenas filas simples.
resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                = "sbns-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = {
    ambiente = var.environment
    projeto  = var.project_name
  }
}

# 5. Criação da Fila (Queue) com boas práticas de resiliência
resource "azurerm_servicebus_queue" "sb_queue" {
  name         = "fila-pedidos"
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id

  # Configurações de Ciclo de Vida da Mensagem
  lock_duration               = "PT1M"  # Tempo que o microsserviço tem para processar (1 minuto)
  max_delivery_count          = 5       # Se falhar 5 vezes, vai direto para a Dead-Letter Queue (DLQ)
  dead_lettering_on_message_expiration = true # Envia para DLQ se a mensagem expirar na fila

  # Retenção e Janelas de Tempo
  default_message_ttl         = "P14D"  # Mensagem vive no máximo 14 dias se ninguém consumir
  requires_duplicate_detection = true
  duplicate_detection_history_time_window = "PT10M" # Ignora mensagens com o mesmo MessageId enviadas em até 10 minutos

  # Ative se precisar garantir ordem estrita FIFO usando Session IDs
  requires_session            = false 
}

# 6. Regra de Acesso (SAS Policy) para os Microsserviços
# Evite usar a chave do Namespace inteiro. Crie chaves escopadas por fila.
resource "azurerm_servicebus_queue_authorization_rule" "queue_auth" {
  name     = "auth-${azurerm_servicebus_queue.sb_queue.name}"
  queue_id = azurerm_servicebus_queue.sb_queue.id

  listen = true
  send   = true
  manage = false # Microsserviços não devem ter permissão de alterar a infraestrutura
}

# 7. Outputs úteis para obter as Connection Strings sem abrir o portal
output "servicebus_connection_string" {
  value     = azurerm_servicebus_queue_authorization_rule.queue_auth.primary_connection_string
  sensitive = true # Esconde a string de conexão nos logs do console
}