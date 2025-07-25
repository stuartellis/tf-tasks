# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#
# Locals for resource identifiers
#
# Use these locals to build resource names, tags and labels.
# They use input variables that are defined in tft_variables.tf
#
# WARNING: TF will create a new resource when you change any local that affects the resource name.

locals {

  # Use these in tags and labels
  meta_component_name       = lower(var.tft_unit_name)
  meta_edition_name         = lower(var.tft_edition_name)
  meta_environment_name     = lower(var.tft_environment_name)
  meta_product_name         = lower(var.tft_product_name)

  # Instance: Full SHA256 hash
  meta_instance_sha256_hash = sha256("${local.meta_product_name}-${local.meta_environment_name}-${local.meta_component_name}-${local.meta_edition_name}")

  # Instance identifier: Use this in resource names
  edition_id = substr(local.meta_instance_sha256_hash, 0, 8)
}

output "meta_instance_sha256_hash" {
  value       = local.meta_instance_sha256_hash
  description = "Meta: The SHA256 hash that identifies this instance of the TF root module."
}

output "meta_instance_edition_id" {
  value       = local.edition_id
  description = "Meta: An identifier for resources managed by this instance of the TF root module."
}
