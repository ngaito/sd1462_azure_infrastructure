resource "azurerm_resource_group" "ngaito-demo" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "ngaito-demo" {
  name                = "ngaito-demo-network"
  location            = azurerm_resource_group.ngaito-demo.location
  resource_group_name = azurerm_resource_group.ngaito-demo.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "ngaito-demo" {
  name                 = "ngaito-demo-subnet"
  virtual_network_name = azurerm_virtual_network.ngaito-demo.name
  resource_group_name  = azurerm_resource_group.ngaito-demo.name
  address_prefixes     = ["10.1.0.0/22"]
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.ngaito-demo.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.ngaito-demo.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = "Standard_B2s"
    type                = "VirtualMachineScaleSets"
    zones  = [1, 2]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 4

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.ngaito-demo.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet" 
  }
}