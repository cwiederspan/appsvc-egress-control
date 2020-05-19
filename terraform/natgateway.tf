# resource "azurerm_public_ip" "ipaddr" {
#   name                = "${local.base_name}-natip"
#   resource_group_name = azurerm_resource_group.group.name
#   location            = azurerm_resource_group.group.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   # zones               = ["1"]
# }

# resource "azurerm_nat_gateway" "nat" {
#   name                = "${local.base_name}-nat"
#   resource_group_name = azurerm_resource_group.group.name
#   location            = azurerm_resource_group.group.location
#   public_ip_address_ids = [azurerm_public_ip.ipaddr.id]
# }

# resource "azurerm_route_table" "routes" {
#   name                = "${local.base_name}-routes"
#   resource_group_name = azurerm_resource_group.group.name
#   location            = azurerm_resource_group.group.location
#   disable_bgp_route_propagation = false
# }

# resource "azurerm_route" "web-egress" {
#   name                   = "web-egress-route"
#   resource_group_name    = azurerm_resource_group.group.name
#   route_table_name       = azurerm_route_table.routes.name
#   address_prefix         = "0.0.0.0/0"
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = ???
# }

# resource "azurerm_subnet_route_table_association" "routes" {
#   subnet_id      = azurerm_subnet.web.id
#   route_table_id = azurerm_route_table.routes.id
# }

# resource "azurerm_subnet_nat_gateway_association" "nat" {
#   subnet_id      = azurerm_subnet.web.id
#   nat_gateway_id = azurerm_nat_gateway.nat.id
# }