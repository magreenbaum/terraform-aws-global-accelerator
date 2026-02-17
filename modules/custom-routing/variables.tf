variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Custom Routing Accelerator
################################################################################

variable "name" {
  description = "The name of the accelerator"
  type        = string
  default     = ""
}

variable "ip_address_type" {
  description = "The value for the address type. Defaults to `IPV4`. Valid values: `IPV4`, `DUAL_STACK`"
  type        = string
  default     = "IPV4"
}

variable "ip_addresses" {
  description = "The IP addresses to use for BYOIP accelerators. If not specified, the service assigns IP addresses. Valid values: 1 or 2 IPv4 addresses"
  type        = list(string)
  default     = []
}

variable "enabled" {
  description = "Indicates whether the accelerator is enabled. Defaults to `true`. Valid values: `true`, `false`"
  type        = bool
  default     = true
}

variable "flow_logs_enabled" {
  description = "Indicates whether flow logs are enabled. Defaults to `false`"
  type        = bool
  default     = false
}

variable "flow_logs_s3_bucket" {
  description = "The name of the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true`"
  type        = string
  default     = null
}

variable "flow_logs_s3_prefix" {
  description = "The prefix for the location in the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true`"
  type        = string
  default     = null
}

################################################################################
# Custom Routing Listener(s)
################################################################################

variable "create_listeners" {
  description = "Controls if listeners should be created (affects only listeners)"
  type        = bool
  default     = true
}

variable "listeners" {
  description = "A map of listener defintions to create"
  type = map(object({
    port_ranges = optional(list(object({
      from_port = optional(number)
      to_port   = optional(number)
    })))
    endpoint_groups = optional(map(object({
      endpoint_group_region = optional(string)
      destination_configuration = optional(list(object({
        from_port = number
        protocols = list(string)
        to_port   = number
      })))
      endpoint_configuration = optional(list(object({
        attachment_arn                 = optional(string)
        client_ip_preservation_enabled = optional(bool)
        endpoint_id                    = optional(string)
        weight                         = optional(number)
      })))
    })))
  }))
  default = {}
}

variable "listeners_timeouts" {
  description = "Create, update, and delete timeout configurations for the listeners"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

################################################################################
# Custom Routing Endpoint Group(s)
################################################################################

# Endpoint groups are nested with the listener definition

variable "endpoint_groups_timeouts" {
  description = "Create, update, and delete timeout configurations for the endpoint groups"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = null
}
