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
  subscription_id = "54040fac-72......"
  tenant_id       = "eabe64c5-68......."
  client_id       = "3926d36a-cc......."
  client_secret   = "jI88Q~hP7XT........"
}

# 3. Criar o Grupo de Recursos
resource "azurerm_resource_group" "rg-teste" {
  name     = "grupoTeste"
  location = "Mexico Central" # "Mexico Central" # "Brazil South"
}

# 4. Rede Virtual (VNET)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnetTeste"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-teste.location
  resource_group_name = azurerm_resource_group.rg-teste.name
}

# 4.1 Sub-rede (Um pedaço da rede para a VM)
resource "azurerm_subnet" "subnet" {
  name                 = "subnetTeste"
  resource_group_name  = azurerm_resource_group.rg-teste.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 5. Interface de Rede (A "placa de rede" da VM)
resource "azurerm_network_interface" "nic" {
  name                = "nic-vm-01"
  location            = azurerm_resource_group.rg-teste.location
  resource_group_name = azurerm_resource_group.rg-teste.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ippubTeste.id
  }
}

# 6. A Máquina Virtual Linux
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-01"
  resource_group_name = azurerm_resource_group.rg-teste.name
  location            = azurerm_resource_group.rg-teste.location
  size                = "Standard_B2as_v2" # Versão barata para testes - Standard_E2s_v3
  admin_username      = "adminuser"
  zone                = "1"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # Autenticação via Senha (para facilitar o seu teste inicial)
  admin_password                  = "SenhaMuitoForte123!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # source_image_reference {
  #  publisher = "Canonical"
  #  offer     = "UbuntuServer"
  #  sku       = "18.04-LTS-gen2"
  #  version   = "latest"
  # }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server" 
    version   = "latest"
  }
}

# 7. IP Publico
resource "azurerm_public_ip" "ippubTeste" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.rg-teste.name
  location            = azurerm_resource_group.rg-teste.location
  allocation_method   = "Static"   # Pode ser Dynamic ou Static
  sku                 = "Standard" # Recomendado para uso com Zonas de Disponibilidade
}

# 8. NSG (Firewall)
resource "azurerm_network_security_group" "my_nsg" {
  name                = "vm-ssh-nsg"
  location            = azurerm_resource_group.rg-teste.location
  resource_group_name = azurerm_resource_group.rg-teste.name

  # Regra para permitir SSH (Porta 22)
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # Cuidado: "*" libera para o mundo todo
    destination_address_prefix = "*"
  }

  # Regra para permitir HTTP (Porta 80)
  security_rule {
    name                       = "HTTP"
    priority                   = 110          # Prioridade deve ser única
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regra para permitir HTTPS (Porta 443)
  security_rule {
    name                       = "HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 9. Associar NIC com NSG
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}
