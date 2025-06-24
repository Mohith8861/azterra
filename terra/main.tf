resource "azurerm_resource_group" "res-0" {
  location = "eastus"
  name     = "DevEnvironment-RG"
}
resource "azurerm_ssh_public_key" "res-1" {
  location            = "eastus"
  name                = "Dev-VM_key"
  public_key          = file("../Dev-VM_key.pub")
  resource_group_name = "DevEnvironment-RG"
  tags = {
    Owner   = "azure-dev-user"
    Project = "DevEnvironment"
  }
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_linux_virtual_machine" "res-2" {
  admin_username        = "azureuser"
  location              = "eastus"
  name                  = "Dev-VM"
  network_interface_ids = [azurerm_network_interface.res-13.id]
  resource_group_name   = "DevEnvironment-RG"
  secure_boot_enabled   = true
  size                  = "Standard_B1s"
  vtpm_enabled          = true
  zone                  = "1"
  additional_capabilities {
  }
  admin_ssh_key { 
    public_key = azurerm_ssh_public_key.res-1.public_key
    username   = "azureuser"
  }
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "ubuntu-24_04-lts"
    publisher = "canonical"
    sku       = "server"
    version   = "latest"
  }
}
# --------------------------------------------------------
resource "azurerm_container_registry" "res-3" {
  admin_enabled       = true
  location            = "eastus"
  name                = "DevEnvironmentACR"
  resource_group_name = "DevEnvironment-RG"
  sku                 = "Basic"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_container_registry_scope_map" "res-4" {
  actions                 = ["repositories/*/metadata/read", "repositories/*/metadata/write", "repositories/*/content/read", "repositories/*/content/write", "repositories/*/content/delete"]
  container_registry_name = "DevEnvironmentACR"
  description             = "Can perform all read, write and delete operations on the registry"
  name                    = "repositories-admin"
  resource_group_name     = "DevEnvironment-RG"
  depends_on = [
    azurerm_container_registry.res-3
  ]
}
resource "azurerm_container_registry_scope_map" "res-5" {
  actions                 = ["repositories/*/content/read"]
  container_registry_name = "DevEnvironmentACR"
  description             = "Can pull any repository of the registry"
  name                    = "repositories-pull"
  resource_group_name     = "DevEnvironment-RG"
  depends_on = [
    azurerm_container_registry.res-3
  ]
}
resource "azurerm_container_registry_scope_map" "res-6" {
  actions                 = ["repositories/*/content/read", "repositories/*/metadata/read"]
  container_registry_name = "DevEnvironmentACR"
  description             = "Can perform all read operations on the registry"
  name                    = "repositories-pull-metadata-read"
  resource_group_name     = "DevEnvironment-RG"
  depends_on = [
    azurerm_container_registry.res-3
  ]
}
resource "azurerm_container_registry_scope_map" "res-7" {
  actions                 = ["repositories/*/content/read", "repositories/*/content/write"]
  container_registry_name = "DevEnvironmentACR"
  description             = "Can push to any repository of the registry"
  name                    = "repositories-push"
  resource_group_name     = "DevEnvironment-RG"
  depends_on = [
    azurerm_container_registry.res-3
  ]
}
resource "azurerm_container_registry_scope_map" "res-8" {
  actions                 = ["repositories/*/metadata/read", "repositories/*/metadata/write", "repositories/*/content/read", "repositories/*/content/write"]
  container_registry_name = "DevEnvironmentACR"
  description             = "Can perform all read and write operations on the registry"
  name                    = "repositories-push-metadata-write"
  resource_group_name     = "DevEnvironment-RG"
  depends_on = [
    azurerm_container_registry.res-3
  ]
}
resource "azurerm_kubernetes_cluster" "res-9" {
  automatic_upgrade_channel    = "patch"
  dns_prefix                   = "Dev-AKS-dns"
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 168
  location                     = "eastus"
  name                         = "Dev-AKS"
  oidc_issuer_enabled          = true
  resource_group_name          = "DevEnvironment-RG"
  workload_identity_enabled    = true
  default_node_pool {
    auto_scaling_enabled = true
    temporary_name_for_rotation = "testpool"
    max_count            = 2
    min_count            = 1
    name                 = "agentpool"
    vm_size = "standard_a2_v2"
    upgrade_settings {
      max_surge = "10%"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  maintenance_window_auto_upgrade {
    day_of_week = "Sunday"
    duration    = 8
    frequency   = "Weekly"
    interval    = 1
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }
  maintenance_window_node_os {
    day_of_week = "Sunday"
    duration    = 8
    frequency   = "Weekly"
    interval    = 1
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }
  depends_on = [
    azurerm_resource_group.res-0
  ]
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.res-3.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.res-9.kubelet_identity[0].object_id
}

# ---------------------------------------------------------------
resource "azurerm_network_interface" "res-13" {
  location            = "eastus"
  name                = "dev-vm555_z1"
  resource_group_name = "DevEnvironment-RG"
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.res-18.id
    subnet_id                     = azurerm_subnet.res-20.id
  }
}
resource "azurerm_network_interface_security_group_association" "res-14" {
  network_interface_id      = azurerm_network_interface.res-13.id
  network_security_group_id = azurerm_network_security_group.res-15.id
}
resource "azurerm_network_security_group" "res-15" {
  location            = "eastus"
  name                = "Dev-VM-nsg"
  resource_group_name = "DevEnvironment-RG"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_network_security_rule" "res-16" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "80"
  direction                   = "Inbound"
  name                        = "AllowAnyHTTPInbound"
  network_security_group_name = "Dev-VM-nsg"
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = "DevEnvironment-RG"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-15
  ]
}
resource "azurerm_network_security_rule" "res-17" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "default-allow-ssh"
  network_security_group_name = "Dev-VM-nsg"
  priority                    = 110
  protocol                    = "Tcp"
  resource_group_name         = "DevEnvironment-RG"
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.res-15
  ]
}
resource "azurerm_public_ip" "res-18" {
  allocation_method   = "Static"
  location            = "eastus"
  name                = "Dev-VM-ip"
  resource_group_name = "DevEnvironment-RG"
  zones               = ["1"]
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
output "public_ip" {
  value = azurerm_public_ip.res-18.ip_address  
}
resource "azurerm_virtual_network" "res-19" {
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  name                = "Dev-Vnet"
  resource_group_name = "DevEnvironment-RG"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_subnet" "res-20" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "Dev-Subnet"
  resource_group_name  = "DevEnvironment-RG"
  virtual_network_name = "Dev-Vnet"
  depends_on = [
    azurerm_virtual_network.res-19
  ]
}
resource "azurerm_subnet" "res-21" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "default"
  resource_group_name  = "DevEnvironment-RG"
  virtual_network_name = "Dev-Vnet"
  depends_on = [
    azurerm_virtual_network.res-19
  ]
}
#-------------------------------------------------
resource "azurerm_storage_account" "res-22" {
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  allow_nested_items_to_be_public = false
  location                        = "eastus"
  name                            = "devstorage8861"
  resource_group_name             = "DevEnvironment-RG"
  tags = {
    Owner   = "azure-dev-user"
    Project = "DevEnvironment"
  }
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_storage_container" "res-24" {
  name               = "misc"
  storage_account_id = "/subscriptions/86bdb61f-551b-4581-bd9d-d6d174e744dc/resourceGroups/DevEnvironment-RG/providers/Microsoft.Storage/storageAccounts/devstorage8861"
  depends_on = [
    azurerm_storage_account.res-22
  ]
}
resource "azurerm_storage_account_queue_properties" "res-26" {
  storage_account_id = azurerm_storage_account.res-22.id
  hour_metrics {
    version = "1.0"
  }
  logging {
    delete  = false
    read    = false
    version = "1.0"
    write   = false
  }
  minute_metrics {
    version = "1.0"
  }
}
