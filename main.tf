terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group
resource "azurerm_resource_group" "default" {
  location = var.resource_group_location
  name     = var.resource_group_name
  #location = "centralindia"
  #name     = "rg-terraformcloudtest"
}

# Create virtual network
resource "azurerm_virtual_network" "default" {
  name                = "VnetTest"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_network_security_group" "default" {
  name                = "test-nsg"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
 
# Create subnet

resource "azurerm_subnet" "default" {
  for_each             = var.subnet_prefix
  name                 = each.value["name"]
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes     = each.value["ip"]
  service_endpoints    = ["Microsoft.Storage"]
  
  dynamic "delegation" {
      for_each = each.value.service_delegation == "true" ? [1] : []
      content {
        name = "delegation"
        service_delegation {
          name = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", ]
      }
    }
  }
  /* dynamic "delegation" {
      for_each = each.value.service_delegation == "true" ? [1] : []
        
      content {
      name = "delegation"

      service_delegation {
      name = "Microsoft.Network/networkInterfaces"

      actions = [
         "Microsoft.Network/networkInterfaces/join/action" ,
      ]
      }
    }
  } */
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default["subnet-1"].id
  network_security_group_id = azurerm_network_security_group.default.id
} 

resource "azurerm_private_dns_zone" "default" {
  name                = "test897-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.default.name

  depends_on = [azurerm_subnet_network_security_group_association.default]
}

resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "test897-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.default.name
  virtual_network_id    = azurerm_virtual_network.default.id
  resource_group_name   = azurerm_resource_group.default.name
}

resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "test897-server"
  resource_group_name    = azurerm_resource_group.default.name
  location               = azurerm_resource_group.default.location
  version                = "13"
  #delegated_subnet_id    = azurerm_subnet.default["subnet-1"].id
  private_dns_zone_id    = azurerm_private_dns_zone.default.id
  administrator_login    = var.postgreadmin_username
  administrator_password = var.postgreadmin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.default]
}
# Create public IPs
resource "azurerm_public_ip" "default" {
  name                = "PublicIPTest"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Dynamic"
}
# Network Interface 
resource "azurerm_network_interface" "default" {
  name                = "myNIC"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.default["subnet-1"].id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id         = azurerm_public_ip.my_terraform_public_ip.id
    
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "default" {
  name                  = "VMTest"
  location              = azurerm_resource_group.default.location
  resource_group_name   = azurerm_resource_group.default.name
  network_interface_ids = [azurerm_network_interface.default.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  computer_name                   = "myvm"
  admin_username                  = var.vmadmin_username
  admin_password                  = var.vmadmin_password
  disable_password_authentication = false
}