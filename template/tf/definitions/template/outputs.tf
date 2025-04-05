# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: [[ license_type ]]
#
# SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: [[ license_type ]]
#

output "ssm_param_meta_stack_present_path" {
  value       = aws_ssm_parameter.stack_present.name
  description = "The path of the SSM Parameter present for any stack deployment."
}
