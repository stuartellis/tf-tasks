<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# Copier Template for TF Tools

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) project. It uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects.

The tasks in the generated projects provide an opinionated configuration for Terraform and OpenTofu. This configuration enables projects to use built-in features of these tools to support:

- Multiple TF components ([modules](https://opentofu.org/docs/language/modules/)) in the same code repository
- Multiple instances of the same TF component with different configurations
- Temporary instances of a TF component for testing or development with [workspaces](https://opentofu.org/docs/language/state/workspaces/).

> This project uses the identifier _TF_ or _tf_ for Terraform and OpenTofu. Both tools accept the same commands and have the same behavior.

## How It Works

First use [Copier](https://copier.readthedocs.io/en/stable/) to either generate a new project, or to add this tooling to an existing project. The tooling is designed to avoid conflicts with other technologies.

Once you have the tooling in a project, you can use it to develop and manage infrastructure with Terraform or OpenTofu. It enables you to work with multiple sets of TF infrastructure code in the same project.

This tooling uses specific files and directories:

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
|    |- definitions/
|    |    |
|    |    |- template/
|    |    |
|    |    |- <generated stack definitions>
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
- Provides a `tf/` directory for TF files.

The tasks:

- Generate a `tmp/tf/` directory for artifacts.
- Only change the contents of the `tf/` and `tmp/tf/` directories.
- Copy the contents of the `template/` directories to new stacks and contexts. Change the contents of these directories as you need.

### Stacks

You define each set of infrastructure code as a separate component. Each of the infrastructure components in the project is a separate TF root [module](https://opentofu.org/docs/language/modules/). This tooling refers to these TF root modules as _stacks_. Each TF stack is a subdirectory in the directory `tf/definitions/`.

> This tooling is expected to be compatible with the [stacks feature of Terraform](https://developer.hashicorp.com/terraform/language/stacks). I do not use or test with the feature, since it is unclear when it will be finalised, or if it will be implemented by OpenTofu.

### Contexts

This tooling uses _contexts_ to provide profiles for TF. Contexts enable you to deploy multiple instances of the same stack with different configurations. These instances may or may not be in different environments. Each context is a subdirectory in the directory `tf/contexts/` that contains a `context.json` file and one `.tfvars` file per stack. The `context.json` file specifies metadata and the settings for TF [remote state](https://opentofu.org/docs/language/state/remote/).

> The directory `tf/contexts/all/` also contains one `.tfvars` file per stack. The `.tfvars` file for a stack in the `all` directory is always used, along with `.tfvars` for the current context. This enables you to share common tfvars across all of the contexts for a stack.

### Shared Modules

The project structure also includes a `tf/modules/` directory to hold TF modules that are shared between stacks in the same project.

### Variants

The variants feature creates extra copies of stacks for development and testing. A variant is a separate instance of a stack, using the configuration from the specified context. Each variant is a TF [workspace](https://opentofu.org/docs/language/state/workspaces).

> If you do not set a variant, TF uses the default workspace for the stack.

### Dependencies Between Stacks

By design, this tooling does not specify or enforce any dependencies between infrastructure components. If you need to execute changes in a particular order, specify that order in whichever system you use to carry out deployments.

## Install

You need [Copier](https://copier.readthedocs.io/en/stable/) to add this template to a project. Use [uv](https://docs.astral.sh/uv/) or [pipx](https://pipx.pypa.io/) to run Copier. These tools enable you to use Copier without installing it.

You can either create a new project with this template or add the template to an existing project. Use the same _copy_ sub-command of Copier for both cases. Run Copier with the _uvx_ or _pipx run_ commands, which download and cache software packages as needed. For example:

```shell
uvx copier copy git+https://github.com/stuartellis/copier-tf-tools your-project-name
```

To update a project again with this template, run these commands:

```shell
cd your-project-name
uvx copier update -A -a .copier-answers-tf-tools.yaml .
```

> By design, the Copier configuration for this template does not change the contents of the `tf/` directory once it has been created.

## Usage

To use the tasks in a generated project you need:

- [Git](https://git-scm.com/)
- A UNIX shell, such as Bash or Fish
- [Task](https://taskfile.dev)
- [Terraform](https://www.terraform.io/) 1.11 and above or [OpenTofu](https://opentofu.org/) 1.9 and above

The TF tasks in the template do not use Python or Copier. This means that they can be run in a restricted environment, such as a continuous integration job.

I recommend that you use a tool version manager to install copies of Terraform and OpenTofu. Consider using either [tenv](https://tofuutils.github.io/tenv/), which is specifically designed for TF tools, or the general-purpose [mise](https://mise.jdx.dev/) framework. The generated projects include a `.terraform-version` file so that your tool version manager can install the Terraform version that you specify.

To see a list of the available tasks in a project, enter _task_ in a terminal window:

```shell
task
```

Tasks for TF stacks use the namespace `tft`. For example, `tft:new` creates the directories and files for a new stack:

```shell
TFT_STACK=example-app task tft:new
```

You need to set these environment variables to work on a stack:

- `TFT_CONTEXT` - The TF configuration to use from `tf/contexts/`
- `TFT_STACK` - The name of the stack in `tf/definitions/`

Set these variables to override the defaults:

- `TFT_PRODUCT_NAME` - The name of the project
- `TFT_CLI_EXE` - The Terraform or OpenTofu executable to use
- `TFT_VARIANT` - See the section on [variants](#variants)
- `TFT_REMOTE_BACKEND` - Enables a remote TF backend

By default, this tooling uses [remote state](https://opentofu.org/docs/language/state/remote/) with TF. Set `TFT_REMOTE_BACKEND` to `false` to use a local TF state file:

```shell
TFT_REMOTE_BACKEND=false
```

> This tooling currently only supports S3 for remote state.

Specify `TFT_CONTEXT` to create a deployment of the stack with the configuration from the specified context:

```shell
TFT_CONTEXT=dev TFT_STACK=example-app task tft:plan
TFT_CONTEXT=dev TFT_STACK=example-app task tft:apply
```

By default, this tooling uses Terraform. To use OpenTofu, set `TFT_CLI_EXE` as an environment variable, with the value `tofu`:

```shell
TFT_CLI_EXE=tofu
```

### Variants

Use the variants feature to deploy extra copies of stacks for development and testing. Each variant is an instance of a stack, using the configuration from the specified context.

Specify `TFT_VARIANT` to create a variant:

```shell
TFT_CONTEXT=dev TFT_STACK=example-app TFT_VARIANT=feature1 task tft:plan
TFT_CONTEXT=dev TFT_STACK=example-app TFT_VARIANT=feature1 task tft:apply
```

The tooling automatically sets the value of the tfvar `variant` to the name of the variant.

Only set `TFT_VARIANT` when you want to create an alternate version of a stack. If you do not specify a variant name, TF uses the default workspace for state, and the value of the tfvar `variant` is `default`.

The [test](https://opentofu.org/docs/cli/commands/test/) feature of TF creates and then immediately destroys resources without storing the state. To ensure that temporary test copies of stacks do not conflict with other copies, the test in the stack template includes code to set the value of `variant` to a random string with the prefix `tt`.

### Resource Names

Use the `environment`, `stack_name` and `variant` tfvars in your TF code to define resource names that are unique for each instance of the resource. This avoids conflicts.

> The test in the stack template includes code to set the value of `variant` to a random string with the prefix `tt`.

The code in the stack template includes the local `standard_prefix` to help you set unique names for resources.

### Available `tft` Tasks

| Name          | Description                                                                                       |
| ------------- | ------------------------------------------------------------------------------------------------- |
| tft:apply     | _terraform apply_ for a stack\*                                                                   |
| tft:check-fmt | Checks whether _terraform fmt_ would change the code for a stack                                  |
| tft:clean     | Remove the generated files for a stack                                                            |
| tft:console   | _terraform console_ for a stack\*                                                                 |
| tft:destroy   | _terraform apply -destroy_ for a stack\*                                                          |
| tft:fmt       | _terraform fmt_ for a stack                                                                       |
| tft:forget    | _terraform workspace delete_ for a variant\*                                                      |
| tft:init      | _terraform init_ for a stack                                                                      |
| tft:new       | Add the source code for a new stack. Copies content from the _tf/definitions/template/_ directory |
| tft:plan      | _terraform plan_ for a stack\*                                                                    |
| tft:rm        | Delete the source code for a stack                                                                |
| tft:test      | _terraform test_ for a stack\*                                                                    |
| tft:validate  | _terraform validate_ for a stack\*                                                                |

\*: These tasks require that you first run `tft:init` to [initialise](https://opentofu.org/docs/cli/commands/init/) the stack.

### Available `tft:context` Tasks

| Name             | Description                                                                  |
| ---------------- | ---------------------------------------------------------------------------- |
| tft:context:list | List the contexts                                                            |
| tft:context:new  | Add a new context. Copies content from the _tf/contexts/template/_ directory |
| tft:context:rm   | Delete the directory for a context                                           |

## Contributing

This project was built for my personal use. I will consider suggestions and Pull Requests, but I might decline anything that makes it less useful for my needs. You are welcome to fork this project.

Some of the configuration files for this project template are provided by my [project baseline](https://github.com/stuartellis/copier-sve-baseline) Copier template. To synchronize a copy of this project template with the baseline template, run these commands:

```shell
cd copier-sve-baseline
copier update -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
