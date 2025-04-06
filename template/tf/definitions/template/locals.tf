# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#

locals {
  standard_prefix = "${var.environment_name}-${var.variant}-${var.stack_name}"
}
