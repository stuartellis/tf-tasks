# SPDX-FileCopyrightText: 2024-present Stuart Ellis <stuart@stuartellis.name>
#
# SPDX-License-Identifier: MIT

run "setup" {
  command = apply

  module {
    source = "./tests/setup"
  }
}

run "match_expected_meta_params" {
  command = apply

  variables {
    variant = run.setup.random_variant_name
  }

  assert {
    condition     = output.ssm_param_meta_stack_present_path == "/metadata/${var.product_name}/${var.stack_name}/${var.environment_name}/${var.variant}/present"
    error_message = "Specified path ${output.ssm_param_meta_stack_present_path} does not expected path /metadata/${var.product_name}/${var.stack_name}/${var.environment_name}/${var.variant}/present."
  }
}
