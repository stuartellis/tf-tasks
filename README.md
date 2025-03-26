<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# copier-tf-tools

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) project. It uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects.

The tasks in the generated projects provide an opinionated set of tools for Terraform and OpenTofu. They use built-in features to support both multiple TF components in the same repository and deploying multiple instances of the same component.

Each of these infrastructure components is a separate TF root module. This tooling refers to these TF root modules as _stacks_.

This tooling uses _contexts_ to provide profiles for TF. Contexts enable you to deploy multiple instances of the same stack with different configurations. These instances may or may not be in different environments. Each context is a directory that contains a `context.json` file and one `.tfvars` file per stack. The `context.json` file specifies the settings for a TF remote backend and metadata.

> The directory `tf/contexts/all/` also contains one `.tfvars` file per stack. The `.tfvars` file for a stack in the `all` directory is always used along with `.tfvars` for the current context.

## Install

You need [Copier](https://copier.readthedocs.io/en/stable/) to add this template to a project. Use [uv](https://docs.astral.sh/uv/) or [pipx](https://pipx.pypa.io/) to run Copier. These tools enable you to use Copier without installing it.

To use the tasks in a generated project you need:

- [Git](https://git-scm.com/)
- A UNIX shell, such as Bash
- [Task](https://taskfile.dev)
- [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/)

The tasks do not require Python. This means that they can be run in a restricted environment, such as a continuous integration job.

> I recommend that you use a tool version manager to install copies of Terraform and OpenTofu. Consider using either [tenv](https://tofuutils.github.io/tenv/), which is specifically designed for TF tools, or the general-purpose [mise](https://mise.jdx.dev/) framework. The generated projects include a `.terraform-version` file for your tool version manager.

## Usage

You can either create a new project with this template or add the template to an existing project. Use the same _copy_ sub-command of Copier for both cases. Run Copier with the _uvx_ or _pipx run_ commands, which download and cache software packages as needed. For example:

```shell
uvx copier copy git+https://github.com/stuartellis/copier-tf-tools your-project-name
```

To update a project again with this template, run these commands:

```shell
cd your-project-name
uvx copier update -a .copier-answers-tf-tools.yaml .
```

To see a list of the available tasks in a project, enter _task_ in a terminal window:

```shell
task
```

Tasks for TF stacks use the namespace `tf`. For example, `tf:new` creates the directories and files for a new stack:

```shell
STACK=example_app task tf:new
```

You need to set these environment variables to work on a stack:

- `CONTEXT` - The TF configuration to use
- `STACK` - Name of stack

Set these variables to override the defaults:

- `PRODUCT_NAME` - The name of the project
- `TF_CLI_EXE` - The Terraform or OpenTofu executable to use
- `VARIANT` - The name of the active TF workspace
- `TF_REMOTE_BACKEND` - Enables a remote TF backend

By default, this tooling uses a local TF state file. We set `TF_REMOTE_BACKEND` to `true` to use S3 as the remote backend for TF:

```shell
TF_REMOTE_BACKEND=true
```

> These tools currently only use S3 as a TF backend.

Specify `CONTEXT` to create a deployment of the stack in the target CONTEXT:

```shell
CONTEXT=dev STACK=example_app task tf:plan
CONTEXT=dev STACK=example_app task tf:apply
```

### Variants

Specify `VARIANT` to create an alternate deployment of the same stack with the same context:

```shell
CONTEXT=dev STACK=example_app VARIANT=feature1 task tf:plan
CONTEXT=dev STACK=example_app VARIANT=feature1 task tf:apply
```

> The variant feature uses TF workspaces. It sets the value of the tfvar `variant` to the name of the variant. Use the `environment`, `stack` and `variant` tfvars to define resource names that are unique.

### Available `tf` Tasks

| Name         | Description                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------- |
| tf:apply     | _terraform apply_ for a stack                                                                     |
| tf:check-fmt | Checks whether _terraform fmt_ would change the code for a stack                                  |
| tf:console   | _terraform console_ for a stack                                                                   |
| tf:destroy   | _terraform apply -destroy_ for a stack                                                            |
| tf:fmt       | _terraform fmt_ for a stack                                                                       |
| tf:init      | _terraform init_ for a stack                                                                      |
| tf:new       | Add the source code for a new stack. Copies content from the _tf/definitions/template/_ directory |
| tf:plan      | _terraform plan_ for a stack                                                                      |
| tf:rm        | Delete the source code for a stack                                                                |
| tf:test      | _terraform test_ for a stack                                                                      |
| tf:validate  | _terraform validate_ for a stack                                                                  |

### Available `tf:context` Tasks

| Name            | Description                                                                  |
| --------------- | ---------------------------------------------------------------------------- |
| tf:context:list | List the contexts                                                            |
| tf:context:new  | Add a new context. Copies content from the _tf/contexts/template/_ directory |
| tf:context:rm   | Delete the directory for a context                                           |

## Contributing

The current version of this project is not for general use.

Some configuration files for this project are managed by my [baseline](https://github.com/stuartellis/copier-sve-baseline) Copier template. To synchronize this project with the baseline template, run these commands:

```shell
cd copier-sve-baseline
copier update -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
