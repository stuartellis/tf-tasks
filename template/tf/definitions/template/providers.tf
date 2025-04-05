# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#
# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT
#

provider "aws" {

  assume_role {
    role_arn = var.tf_exec_role_arn
  }

  default_tags {
    tags = {
      Environment = var.environment_name
      Product     = var.product_name
      Provisioner = "Terraform"
      Stack       = var.stack_name
      Variant     = var.variant
    }
  }
}
