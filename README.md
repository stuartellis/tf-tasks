<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# Copier Template for TF Tasks

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) project.

The tooling uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects. The tasks provide an opinionated configuration for Terraform and OpenTofu. This configuration enables projects to use built-in features of these tools to support:

- Multiple separate infrastructure components ([root modules](https://opentofu.org/docs/language/modules/)) in the same code repository, as self-contained [units](#units)
- Multiple instances of the same component with different configurations with [contexts](#contexts)
- Temporary instances of a component for testing or development with [workspaces](https://opentofu.org/docs/language/state/workspaces/).
- [Integration testing](#testing) for every component.
- [Switching between Terraform and OpenTofu](#using-opentofu). Use the same tasks for both.

> We use the identifier _TF_ or _tf_ for Terraform and OpenTofu. Both tools accept the same commands and have the same behavior. The tooling itself is just called `tft` in the documentation and code.

## Table of Contents

- [A Quick Example](#a-quick-example)
- [How It Works](#how-it-works)
- [Install](#install)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## A Quick Example

To start a new project:

```shell
copier copy git+https://github.com/stuartellis/tf-tasks my-project
cd my-project
TFT_CONTEXT=dev task tft:context:new
TFT_UNIT=my-app task tft:new
```

The `tft:new` task creates a unit, a self-contained Terraform root module. The unit includes code for AWS, so that it will work immediately once the tfvar `tf_exec_role_arn` for the context is set to the IAM role that TF will use. Enable remote state storage by adding the settings to the [context](#contexts), or use [local state](#using-local-tf-state).

You can then start working with your TF module:

```shell
# Set a default context and unit
export TFT_CONTEXT=dev TFT_UNIT=my-app

# Run tasks on the unit with the configuration from the context
task tft:init
task tft:plan
task tft:apply
```

```shell
# Specifically set the unit and context for one task
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:test
```

## How It Works

First, you use [Copier](https://copier.readthedocs.io/en/stable/) to either generate a new project, or to add this tooling to an existing project.

The tooling uses specific files and directories:

```shell
|- tasks/
|   |
|   |- tft/
|       |- Taskfile.yaml
|
|- tf/
|    |- .gitignore
|    |
|    |- contexts/
|    |   |
|    |   |- all/
|    |   |
|    |   |- template/
|    |   |
|    |   |- <generated contexts>
|    |
|    |- units/
|    |    |
|    |    |- template/
|    |    |
|    |    |- <generated unit definitions>
|    |
|    |- modules/
|
|- tmp/
|    |
|    |- tf/
|
|- .gitignore
|- .terraform-version
|- Taskfile.yaml
```

The Copier template:

- Adds a `.gitignore` file and a `Taskfile.yaml` file to the root directory of the project, if these do not already exist.
- Provides a `.terraform-version` file.
- Provides the file `tasks/tft/Taskfile.yaml` to the project. This file contains the task definitions.
- Provides a `tf/` directory structure for TF files and configuration.

The tasks:

- Generate a `tmp/tf/` directory for artifacts.
- Only change the contents of the `tf/` and `tmp/tf/` directories.
- Copy the contents of the `template/` directories to new units and contexts. These provide consistent structures for each component.

### Units

You define each set of infrastructure code as a separate component. Each of the infrastructure components in the project is a separate TF root [module](https://opentofu.org/docs/language/modules/). This tooling refers to these TF root modules as _units_. Each TF unit is a subdirectory in the directory `tf/units/`.

To create a new unit, use the `tft:new` task:

```shell
TFT_UNIT=my-app task tft:new
```

The tooling creates each new unit as a copy of the files in `tf/units/template/`. The template directory contains a complete, working TF module for AWS resources. This means that each new unit is immediately ready to use.

You are free to change units as you need. For example, you can completely remove the AWS resources. The tooling only requires that a unit is a valid TF module with these tfvars:

- `environment_name` (string)
- `product_name` (string)
- `unit_name` (string)
- `variant` (string)

### Contexts

This tooling uses _contexts_ to provide profiles for TF. Contexts enable you to deploy multiple instances of the same unit with different configurations.

To create a new context, use the `tft:context:new` task:

```shell
TFT_CONTEXT=dev task tft:context:new
```

Each context is a subdirectory in the directory `tf/contexts/` that contains a `context.json` file and one `.tfvars` file per unit.

The `context.json` file is the configuration file for the context. It specifies metadata and settings for TF [remote state](https://opentofu.org/docs/language/state/remote/). Each `context.json` file specifies two items of metadata:

- `description`
- `environment`

The `description` is deliberately not used by the tooling, so that you may use it however you wish. The `environment` is a string that is automatically provided to TF as the tfvar `environment_name`. There are no limitations on how your code uses this tfvar.

Here is an example of a `context.json` file:

```json
{
  "metadata": {
    "description": "Cloud development environment",
    "environment": "dev"
  },
  "backend_s3": {
    "tfstate_bucket": "789000123456-tf-state-dev-eu-west-2",
    "tfstate_ddb_table": "789000123456-tf-lock-dev-eu-west-2",
    "tfstate_dir": "dev",
    "region": "eu-west-2",
    "role_arn": "arn:aws:iam::789000123456:role/my-tf-state-role"
  }
}
```

To enable you to share common tfvars across all of the contexts for a unit, the directory `tf/contexts/all/` contains one `.tfvars` file for each unit. The `.tfvars` file for a unit in the `all` directory is always used, along with `.tfvars` for the current context.

The tooling creates each new context as a copy of files in `tf/contexts/template/`. It uses `standard.tfvars` to create the tfvars files that are created for new units.

### Variants

The variants feature creates extra copies of units for development and testing. A variant is a separate instance of a unit. Each variant of a unit uses the same configuration as other instances with the specified context, but has a unique identifier. Every variant is a TF [workspace](https://opentofu.org/docs/language/state/workspaces), so has separate state.

> If you do not specify a named variant, TF uses the default workspace for the unit.

### Managing Resource Names

Use the `environment`, `unit_name` and `variant` tfvars in your TF code to define resource names that are unique for each instance of the resource. This avoids conflicts.

The code in the unit template includes the local `standard_prefix` to help you set unique names for resources.

> The test in the unit template includes code to set the value of `variant` to a random string with the prefix `tt`. This ensures that test copies of resources do not conflict with existing copies.

### Shared Modules

The project structure also includes a `tf/shared/` directory to hold TF modules that are shared between root modules in the same project. To share modules between projects, [publish them to a registry](https://opentofu.org/docs/language/modules/#published-modules).

### Dependencies Between Units

By design, this tooling does not specify or enforce any dependencies between infrastructure components. If you need to execute changes in a particular order, specify that order in whichever system you use to carry out deployments.

> This tooling does not explicitly support or conflict with the [stacks feature of Terraform](https://developer.hashicorp.com/terraform/language/stacks). I do not currently test with the stacks feature. It is unclear when this feature will be finalised, or if an equivalent will be implemented by OpenTofu.

## Install

You need [Git](https://git-scm.com/) and [Copier](https://copier.readthedocs.io/en/stable/) to add this template to a project. Use [uv](https://docs.astral.sh/uv/) or [pipx](https://pipx.pypa.io/) to run Copier. These tools enable you to use Copier without installing it.

You can either create a new project with this template or add the template to an existing project. Use the same _copy_ sub-command of Copier for both cases. Run Copier with the _uvx_ or _pipx run_ commands, which download and cache software packages as needed. For example:

```shell
uvx copier copy git+https://github.com/stuartellis/tf-tasks my-project
```

I recommend that you use a tool version manager to install copies of Terraform and OpenTofu. Consider using either [tenv](https://tofuutils.github.io/tenv/), which is specifically designed for TF tools, or the general-purpose [mise](https://mise.jdx.dev/) framework. The generated projects include a `.terraform-version` file so that your tool version manager can install the Terraform version that you specify.

## Usage

To use the tasks in a generated project you need:

- A UNIX shell, such as Bash or Fish
- [Git](https://git-scm.com/)
- [Task](https://taskfile.dev)
- [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/)

The TF tasks in the template do not use Python or Copier. This means that they can be run in a restricted environment, such as a continuous integration job.

To see a list of the available tasks in a project, enter _task_ in a terminal window:

```shell
task
```

> The tasks use the namespace `tft`. This means that they do not conflict with any other tasks in the project.

Before you manage resources with TF, first create at least one context:

```shell
TFT_CONTEXT=dev task tft:context:new
```

This creates a new context. Edit the `context.json` file in the directory `tf/contexts/<CONTEXT>/` to set the `environment` name and specify the settings for the [remote state](https://opentofu.org/docs/language/state/remote/) storage that you want to use.

> This tooling currently only supports Amazon S3 for remote state storage.

Next, create a unit:

```shell
TFT_UNIT=my-app task tft:new
```

Use `TFT_CONTEXT` and `TFT_UNIT` to create a deployment of the unit with the configuration from the specified context:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app
task tft:init
task tft:plan
task tft:apply
```

> You will see a warning when you run `init` with a current version of Terraform. This is because Hashicorp are [deprecating the use of DynamoDB with S3 remote state](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking). To support older versions of Terraform, this tooling will continue to use DynamoDB for a period of time.

### The `tft` Tasks

| Name          | Description                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------ |
| tft:apply     | _terraform apply_ for a unit\*                                                                   |
| tft:check-fmt | Checks whether _terraform fmt_ would change the code for a unit                                  |
| tft:clean     | Remove the generated files for a unit                                                            |
| tft:console   | _terraform console_ for a unit\*                                                                 |
| tft:destroy   | _terraform apply -destroy_ for a unit\*                                                          |
| tft:fmt       | _terraform fmt_ for a unit                                                                       |
| tft:forget    | _terraform workspace delete_ for a variant\*                                                     |
| tft:init      | _terraform init_ for a unit. An alias for `tft:init:s3`.                                         |
| tft:new       | Add the source code for a new unit. Copies content from the _tf/units/template/_ directory |
| tft:plan      | _terraform plan_ for a unit\*                                                                    |
| tft:rm        | Delete the source code for a unit                                                                |
| tft:test      | _terraform test_ for a unit\*                                                                    |
| tft:validate  | _terraform validate_ for a unit\*                                                                |

\*: These tasks require that you first [initialise](https://opentofu.org/docs/cli/commands/init/) the unit.

### The `tft:context` Tasks

| Name             | Description                                                                  |
| ---------------- | ---------------------------------------------------------------------------- |
| tft:context:list | List the contexts                                                            |
| tft:context:new  | Add a new context. Copies content from the _tf/contexts/template/_ directory |
| tft:context:rm   | Delete the directory for a context                                           |

### The `tft:init` Tasks

| Name           | Description                                               |
| -------------- | --------------------------------------------------------- |
| tft:init:local | _terraform init_ for a unit, with local state.            |
| tft:init:s3    | _terraform init_ for a unit, with Amazon S3 remote state. |

### Settings for Features

Set these variables to override the defaults:

- `TFT_PRODUCT_NAME` - The name of the project
- `TFT_CLI_EXE` - The Terraform or OpenTofu executable to use
- `TFT_VARIANT` - See the section on [variants](#variants)
- `TFT_REMOTE_BACKEND` - Set to _false_ to force the use of local TF state

### Updating TF Tasks

To update projects with the latest version of this template, use the [update feature of Copier](https://copier.readthedocs.io/en/stable/updating/):

```shell
cd my-project
uvx copier update -A -a .copier-answers-tf-task.yaml .
```

This synchronizes the files in your project that the template manages with the latest release of the template.

> Copier only changes the files and directories that are managed by the template.

### Using Variants

Use the variants feature to deploy extra copies of units for development and testing. Each variant of a unit uses the same configuration as other instances with the specified context.

Specify `TFT_VARIANT` to create a variant:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app TFT_VARIANT=feature1
task tft:plan
task tft:apply
```

The tooling automatically sets the value of the tfvar `variant` to match `TFT_VARIANT`. This ensures that every variant has a unique identifier that can be used in TF code.

Only set `TFT_VARIANT` when you want to create an alternate version of a unit. If you do not specify a variant name, TF uses the default workspace for state, and the value of the tfvar `variant` is `default`.

### Testing

This tooling supports the [test](https://opentofu.org/docs/cli/commands/test/) features of TF. Each unit includes a minimum test configuration, so that you can run immediately run tests on the module as soon as it is created.

A test creates and then immediately destroys resources without storing the state. To ensure that temporary test copies of units do not conflict with other copies of the resources, the test in the unit template includes code to set the value of `variant` to a random string with the prefix `tt`.

To validate a unit before any resources are deployed, use the `tft:validate` task:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app
task tft:validate
```

To run tests on a unit, use the `tft:test` task:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app
task tft:test
```

The tests create and destroy temporary copies of resources on the cloud services that being managed. Check the expected behaviour of the resources, because cloud services may not immediately remove some types of resources.

### Using Local TF State

By default, this tooling uses Amazon S3 for [remote state storage](https://opentofu.org/docs/language/state/remote/). To initialize a unit with local state storage, use the task `tft:init:local` rather than `tft:init`:

```shell
task tft:init:local
```

To use local state, you will also need to comment out the `backend "s3" {}` block in the `main.tf` file.

> I highly recommend that you only use TF local state for prototyping. Local state means that the resources can only be managed from a computer that has access to the state files.

### Using OpenTofu

By default, this tooling uses the copy of Terraform that is found on your `PATH`. Set `TFT_CLI_EXE` as an environment variable to specify the path to the tool that you wish to use. For example, to use OpenTofu, set `TFT_CLI_EXE` with the value `tofu`:

```shell
TFT_CLI_EXE=tofu
```

## Contributing

This project was built for my personal use. I will consider suggestions and Pull Requests, but I may decline anything that makes it less useful for my needs. You are welcome to fork this project.

Some of the configuration files for this project template are provided by my [project baseline Copier template](https://github.com/stuartellis/copier-sve-baseline). To synchronize a copy of this project template with the baseline template, run these commands:

```shell
cd tf-tasks
copier update -A -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
