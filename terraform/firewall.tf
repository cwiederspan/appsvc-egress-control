resource "azurerm_public_ip" "ipaddr" {
  name                = "${local.base_name}-fwip"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  # zones               = ["1"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"    # Must be this value
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_firewall" "firewall" {
  name                = "${local.base_name}-fw"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  ip_configuration {
    name                 = "${local.base_name}-fwip"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.ipaddr.id
  }
}

resource "azurerm_firewall_application_rule_collection" "rule" {
  name                = "azure-services"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.group.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "allow-azure-functions"

    source_addresses = azurerm_subnet.web.address_prefixes

    target_fqdns = [
      "*.azurewebsites.net",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_route_table" "routes" {
  name                = "${local.base_name}-routes"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  disable_bgp_route_propagation = false
}

resource "azurerm_route" "web-egress" {
  name                   = "web-egress-route"
  resource_group_name    = azurerm_resource_group.group.name
  route_table_name       = azurerm_route_table.routes.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "routes" {
  subnet_id      = azurerm_subnet.web.id
  route_table_id = azurerm_route_table.routes.id
}