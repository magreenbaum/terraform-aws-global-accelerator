################################################################################
# Custom Routing Accelerator
################################################################################

resource "aws_globalaccelerator_custom_routing_accelerator" "this" {
  count = var.create ? 1 : 0

  name            = var.name
  ip_address_type = var.ip_address_type
  ip_addresses    = var.ip_addresses
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled ? [var.flow_logs_enabled] : []
    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = var.tags
}

################################################################################
# Custom Routing Listener(s)
################################################################################

resource "aws_globalaccelerator_custom_routing_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if var.create && var.create_listeners }

  accelerator_arn = aws_globalaccelerator_custom_routing_accelerator.this[0].id

  dynamic "port_range" {
    for_each = each.value.port_ranges != null ? each.value.port_ranges : []
    content {
      from_port = port_range.value.from_port
      to_port   = port_range.value.to_port
    }
  }

  dynamic "timeouts" {
    for_each = var.listeners_timeouts != null ? [var.listeners_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

################################################################################
# Custom Routing Endpoint Group(s)
################################################################################
locals {
  endpoint_groups = flatten([
    for listener, listener_configs in var.listeners : [
      for endpoint_group, endpoint_group_configs in listener_configs.endpoint_groups : {
        listener               = listener
        endpoint_group         = endpoint_group
        endpoint_group_configs = endpoint_group_configs
      }
    ] if listener_configs.endpoint_groups != null
  ])
}

resource "aws_globalaccelerator_custom_routing_endpoint_group" "this" {
  for_each = { for k, v in local.endpoint_groups : "${v.listener}:${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn          = aws_globalaccelerator_custom_routing_listener.this[each.value.listener].id
  endpoint_group_region = each.value.endpoint_group_configs.endpoint_group_region

  dynamic "destination_configuration" {
    for_each = each.value.endpoint_group_configs.destination_configuration != null ? each.value.endpoint_group_configs.destination_configuration : []
    content {
      from_port = destination_configuration.value.from_port
      protocols = destination_configuration.value.protocols
      to_port   = destination_configuration.value.to_port
    }
  }

  dynamic "endpoint_configuration" {
    for_each = each.value.endpoint_group_configs.endpoint_configuration != null ? each.value.endpoint_group_configs.endpoint_configuration : []
    content {
      endpoint_id = endpoint_configuration.value.endpoint_id
    }
  }

  dynamic "timeouts" {
    for_each = var.endpoint_groups_timeouts != null ? [var.endpoint_groups_timeouts] : []
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}
