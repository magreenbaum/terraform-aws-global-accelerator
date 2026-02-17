################################################################################
# Accelerator
################################################################################

resource "aws_globalaccelerator_accelerator" "this" {
  count = var.create ? 1 : 0

  name            = var.name
  ip_address_type = var.ip_address_type
  ip_addresses    = var.ip_addresses
  enabled         = var.enabled

  dynamic "attributes" {
    for_each = var.flow_logs_enabled ? [1] : []
    content {
      flow_logs_enabled   = var.flow_logs_enabled
      flow_logs_s3_bucket = var.flow_logs_s3_bucket
      flow_logs_s3_prefix = var.flow_logs_s3_prefix
    }
  }

  tags = var.tags
}

################################################################################
# Listener(s)
################################################################################

resource "aws_globalaccelerator_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if var.create && var.create_listeners }

  accelerator_arn = aws_globalaccelerator_accelerator.this[0].id
  client_affinity = each.value.client_affinity
  protocol        = each.value.protocol

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
# Endpoint Group(s)
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

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = { for k, v in local.endpoint_groups : "${v.listener}:${v.endpoint_group}" => v if var.create && var.create_listeners }

  listener_arn = aws_globalaccelerator_listener.this[each.value.listener].id

  endpoint_group_region         = each.value.endpoint_group_configs.endpoint_group_region
  health_check_interval_seconds = each.value.endpoint_group_configs.health_check_interval_seconds
  health_check_path             = each.value.endpoint_group_configs.health_check_path
  health_check_port             = each.value.endpoint_group_configs.health_check_port
  health_check_protocol         = each.value.endpoint_group_configs.health_check_protocol
  threshold_count               = each.value.endpoint_group_configs.threshold_count
  traffic_dial_percentage       = each.value.endpoint_group_configs.traffic_dial_percentage

  dynamic "endpoint_configuration" {
    for_each = [for e in each.value.endpoint_group_configs.endpoint_configuration : e if e.endpoint_id != null]
    content {
      attachment_arn                 = endpoint_configuration.value.attachment_arn
      client_ip_preservation_enabled = endpoint_configuration.value.client_ip_preservation_enabled
      endpoint_id                    = endpoint_configuration.value.endpoint_id
      weight                         = endpoint_configuration.value.weight
    }
  }

  dynamic "port_override" {
    for_each = each.value.endpoint_group_configs.port_override != null ? each.value.endpoint_group_configs.port_override : []
    content {
      endpoint_port = port_override.value.endpoint_port
      listener_port = port_override.value.listener_port
    }
  }

  dynamic "timeouts" {
    for_each = var.endpoint_groups_timeouts != null ? [var.endpoint_groups_timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
