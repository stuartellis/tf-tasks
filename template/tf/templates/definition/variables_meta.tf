# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#
# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#

variable "environment_name" {
  type = string
}

variable "product_name" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "variant" {
  type = string
}

variable "tf_exec_role_arn" {
  type = string
}
