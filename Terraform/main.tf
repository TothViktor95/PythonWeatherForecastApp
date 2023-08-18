terraform {
  cloud {
    organization = "tothviktor1995"
    workspaces {
      name = "azure1"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.41.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "23e471d7-22d5-402c-b703-eef64b84fd42"
}

resource "azurerm_resource_group" "ResourceGroup1" {
  name     = "ResourceGroup1"
  location = "northeurope"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "virtualNetwork1" {
  name                = "virtualNetwork1"
  resource_group_name = azurerm_resource_group.ResourceGroup1.name
  location            = azurerm_resource_group.ResourceGroup1.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.ResourceGroup1.name
  virtual_network_name = azurerm_virtual_network.virtualNetwork1.name
  address_prefixes     = ["10.123.1.0/24"]

}

resource "azurerm_network_security_group" "securityGroup1" {
  name                = "securityGroup1"
  location            = azurerm_resource_group.ResourceGroup1.location
  resource_group_name = azurerm_resource_group.ResourceGroup1.name
  tags = {
    environment = "dev"
  }

  security_rule {
    name                       = "securityRule1"
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

resource "azurerm_subnet_network_security_group_association" "subnetSecurityAssociation1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.securityGroup1.id
}

resource "azurerm_public_ip" "publicIP1" {
  name                = "publicIP1"
  resource_group_name = azurerm_resource_group.ResourceGroup1.name
  location            = azurerm_resource_group.ResourceGroup1.location
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "networkInterface1" {
  name                = "networkInterface1"
  location            = azurerm_resource_group.ResourceGroup1.location
  resource_group_name = azurerm_resource_group.ResourceGroup1.name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIP1.id
  }
  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "AzureUbuntuServer1" {
  name                = "AzureUbuntuServer1"
  resource_group_name = azurerm_resource_group.ResourceGroup1.name
  location            = azurerm_resource_group.ResourceGroup1.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.networkInterface1.id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tf_azure1_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  timeouts {
    create = "20m"
    delete = "20m"
  }

  provisioner "local-exec" {
    command = templatefile("ubuntu-ssh-script.tpl", {
      hostname = self.public_ip_address,
      user = "adminuser",
      identityfile = "~/.ssh/tf_azure1_key"
    })
    # interpreter = ["Powershell", "-Command"] # windows
      interpreter = [ "bash", "-c" ]   # linux
  }

  tags = {
    environment = "dev"
  }
}



