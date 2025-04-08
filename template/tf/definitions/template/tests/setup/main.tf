# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#

terraform {
  required_version = "> 1.0.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

resource "random_string" "variant_suffix" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

output "random_variant_name" {
  value       = "tt${random_string.variant_suffix.result}"
  description = "A random variant name."
}
