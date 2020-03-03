provider "azurerm" {
  version = "2.0.0"

  client_id       = ""
  client_secret   = ""
  subscription_id = ""
  tenant_id       = ""

  features {}

}

provider "github" {
  version = "2.3.2"

  individual = true
  anonymous  = true
}

# github user public ssh key
module "github_user" {
  source = "github.com/kevinhead/github/d/github_user"

  username = "kevinhead"
}

module "azurerm_resource_group" {
  source = "github.com/kevinhead/azurerm/r/azurerm_resource_group"

  location = "East US"
  name     = "example-resources"
}

module "azurerm_virtual_network" {
  source = "github.com/kevinhead/azurerm/r/azurerm_virtual_network"

  address_space       = ["10.0.0.0/16"]
  location            = module.azurerm_resource_group.this.location
  name                = "example-network"
  resource_group_name = module.azurerm_resource_group.this.name
}

module "azurerm_subnet" {
  source = "github.com/kevinhead/azurerm/r/azurerm_subnet"

  address_prefix       = "10.0.2.0/24"
  name                 = "internal"
  resource_group_name  = module.azurerm_resource_group.this.name
  virtual_network_name = module.azurerm_virtual_network.this.name
}

module "azurerm_network_interface" {
  source = "github.com/kevinhead/azurerm/r/azurerm_network_interface"

  location            = module.azurerm_resource_group.this.location
  name                = "example-nic"
  resource_group_name = module.azurerm_resource_group.this.name

  ip_configuration = [{
    name                          = "internal"
    primary                       = null
    private_ip_address            = null
    private_ip_address_allocation = "dynamic"
    private_ip_address_version    = null
    public_ip_address_id          = null
    subnet_id                     = module.azurerm_subnet.id
  }]
}

module "azurerm_linux_virtual_machine" {
  source = "github.com/kevinhead/azurerm/r/azurerm_linux_virtual_machine"

  admin_username        = "kevinhead"
  location              = module.azurerm_resource_group.this.location
  name                  = "example-machine"
  network_interface_ids = [module.azurerm_network_interface.id]
  resource_group_name   = module.azurerm_resource_group.this.name
  size                  = "Standard_F2"

  admin_ssh_key = [{
    public_key = module.github_user.ssh_keys[0]
    username   = "kevinhead"
  }]

  os_disk = [{
    caching                   = "ReadWrite"
    diff_disk_settings        = []
    disk_encryption_set_id    = null
    disk_size_gb              = null
    name                      = null
    storage_account_type      = "Standard_LRS"
    write_accelerator_enabled = null
  }]

  source_image_reference = [{
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }]

}
