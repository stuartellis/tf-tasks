<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# Copier Template for TF Tooling

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) project. It uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects.

The tasks in the generated projects provide an opinionated configuration for Terraform and OpenTofu. This configuration enables it to use built-in features of these tools to support:

- Multiple TF components in the same code repository
- Multiple instances of the same TF component with different configurations
- Temporary instances of a TF component for testing or development with [workspaces](https://opentofu.org/docs/language/state/workspaces/).

> This project always uses the identifier _TF_ or _tf_ where possible, rather than Terraform or OpenTofu. This enables you to use the same tasks and code with both tools.

## How It Works

First use Copier to either generate a new project, or to add this tooling to an existing project. This tooling designed to avoid conflicts with other technologies.

Once you have the tooling in a project, you can use it to develop and manage infrastructure with Terraform or OpenTofu. It enables you to work with multiple sets of TF infrastructure code in the same project. Each set of infrastructure code is a separate component.

Each of the infrastructure components in the project is a separate TF root module. This tooling refers to these TF root modules as _stacks_. The project puts TF stacks in the directory `tf/definitions/`.

This tooling uses _contexts_ to provide profiles for TF. Contexts enable you to deploy multiple instances of the same stack with different configurations. These instances may or may not be in different environments. Each context is a directory that contains a `context.json` file and one `.tfvars` file per stack. The `context.json` file specifies metadata and the settings for a TF remote backend.

> The directory `tf/contexts/all/` also contains one `.tfvars` file per stack. The `.tfvars` file for a stack in the `all` directory is always used along with `.tfvars` for the current context. This enables you to share common tfvars across all of the contexts for a stack.

The project structure also includes a `tf/modules/` directory to hold TF modules that are shared between stacks in the same project.

By design, this tooling does not specify or enforce any dependencies between infrastructure components. If you need to execute changes in a particular order, specify that order in whichever system you use to carry out deployments.

This tooling uses specific files and directories to avoid conflicts with other tools. It adds a `tf/` directory and the file `tasks/tf/Taskfile.yaml` to the project. It also adds a `.gitignore` file and a `Taskfile.yaml` file to the root directory of the project if these do not already exist. Tasks generate a `tmp/tf/` directory for artifacts. It only changes the contents of the `tf/` and `tmp/tf/` directories.

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

> Updates only currently only change the Taskfile `tasks/tf/Taskfile.yaml`. By design, the Copier configuration for this template does not change the contents of the `tf/` directory once it has been created.

## Usage

To use the tasks in a generated project you need:

- [Git](https://git-scm.com/)
- A UNIX shell, such as Bash or Fish
- [Task](https://taskfile.dev)
- [Terraform](https://www.terraform.io/) 1.11 and above or [OpenTofu](https://opentofu.org/) 1.9 and above

You only need Python and Copier to create projects from this template. The tasks in the template do not use Python or Copier. This means that they can be run in a restricted environment, such as a continuous integration job.

I recommend that you use a tool version manager to install copies of Terraform and OpenTofu. Consider using either [tenv](https://tofuutils.github.io/tenv/), which is specifically designed for TF tools, or the general-purpose [mise](https://mise.jdx.dev/) framework. The generated projects include a `.terraform-version` file so that your tool version manager can install the Terraform version that you specify.

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

By default, this tooling uses S3 as the remote backend for TF. We set `TF_REMOTE_BACKEND` to `false` to a local TF state file:

```shell
TF_REMOTE_BACKEND=false
```

> This tooling currently only supports S3 as a remote TF backend.

Specify `CONTEXT` to create a deployment of the stack in the target CONTEXT:

```shell
CONTEXT=dev STACK=example_app task tf:plan
CONTEXT=dev STACK=example_app task tf:apply
```

By default, this tooling uses Terraform. To use OpenTofu, set `TF_CLI_EXE` as an environment variable, with the value `tofu`:

```shell
TF_CLI_EXE=tofu
```

### Variants

Specify `VARIANT` to create an alternate deployment of the same stack with the same context:

```shell
CONTEXT=dev STACK=example_app VARIANT=feature1 task tf:plan
CONTEXT=dev STACK=example_app VARIANT=feature1 task tf:apply
```

The variant feature uses TF workspaces. It sets the value of the tfvar `variant` to the name of the variant. Use the `environment`, `stack` and `variant` tfvars to define resource names that are unique and do not conflict. The `tf:test` task generates random variant names that have the prefix `t-` to ensure that test copies of stacks do not conflict with other copies of the stack.

### Available `tf` Tasks

| Name         | Description                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------- |
| tf:apply     | _terraform apply_ for a stack                                                                     |
| tf:check-fmt | Checks whether _terraform fmt_ would change the code for a stack                                  |
| tf:clean     | Remove the generated files for a stack                                                            |
| tf:console   | _terraform console_ for a stack                                                                   |
| tf:destroy   | _terraform apply -destroy_ for a stack                                                            |
| tf:fmt       | _terraform fmt_ for a stack                                                                       |
| tf:forget    | _terraform workspace delete_ for a variant                                                        |
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

This project was built for my personal use. I will consider suggestions and Pull Requests, but may decline anything that makes it less useful for my needs. You are welcome to fork this project.

Some of the configuration files for this project template are provided by my [project baseline](https://github.com/stuartellis/copier-sve-baseline) Copier template. To synchronize a copy of this project template with the baseline template, run these commands:

```shell
cd copier-sve-baseline
copier update -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
