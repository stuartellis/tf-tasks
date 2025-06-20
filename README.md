<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# Copier Template for TF Tasks

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) in a [monorepo](https://en.wikipedia.org/wiki/Monorepo).

The tooling uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects. It provides an opinionated configuration for Terraform and OpenTofu. This configuration enables projects to use built-in features of these tools to support:

- Multiple infrastructure components in the same code repository. Each [unit](#units) is a complete [root module](https://opentofu.org/docs/language/modules/).
- Multiple instances of the same component with [different configurations](#contexts)
- [Disposable instances](#extra-instances) of a component for development and testing. Use this to create instances for the branches of your code as you need them.
- [Integration testing](#testing) for every component.
- [Migrating from Terraform to OpenTofu](#using-opentofu). You use the same tasks for both.

> This uses the identifier _TF_ or _tf_ for Terraform and OpenTofu. Both tools accept the same commands and have the same behavior. The tooling itself is just called `tft` in the documentation and code.

## Table of Contents

- [Quick Examples](#quick-examples)
- [How It Works](#how-it-works)
- [Install](#install)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Quick Examples

To start a new project:

```shell
uvx copier copy git+https://github.com/stuartellis/tf-tasks my-project
cd my-project
TFT_CONTEXT=dev task tft:context:new
TFT_UNIT=my-app task tft:new
```

The `tft:new` task creates a unit, a complete Terraform root module. This root module includes code for AWS, so that it can work immediately. Enable remote state storage by adding the settings to the [context](#contexts), or use [local state](#using-local-tf-state). Set to the AWS IAM role for TF with the tfvar `tf_exec_role_arn`.

You can then start working with your TF module:

```shell
# Set a default context and unit
export TFT_CONTEXT=dev TFT_UNIT=my-app

# Run tasks on the unit with the configuration from the context
task tft:init
task tft:plan
task tft:apply
```

You can also specifically set the unit and context for one task. This example runs the [integration tests](#testing) for the module:

```shell
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:test
```

To create a disposable copy of the resources for a module, just set an identifier for the extra copy:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app

# Create a disposable copy of my-app
TFT_EDITION=copy2 task tft:plan
TFT_EDITION=copy2 task tft:apply

# Destroy the extra copy of my-app
TFT_EDITION=copy2 task tft:destroy

# Clean-up: Delete the remote TF state for the extra copy of my-app
TFT_EDITION=copy2 task tft:forget
```

To see a list of all of the available tasks in a project, enter _task_ in a terminal window:

```shell
task
```

If you have autocompletion for Task, this will show you commands as you type.

## How It Works

First, you run [Copier](https://copier.readthedocs.io/en/stable/) to either generate a new project, or to add this tooling to an existing project.

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

You define a set of infrastructure code as a component. Each of the infrastructure components in a project is a separate TF root [module](https://opentofu.org/docs/language/modules/), so that it can be created, tested, updated or destroyed independently of the others.

This tooling refers to these TF root modules as _units_. Each TF unit is a subdirectory in the directory `tf/units/`.

To create a new unit, use the `tft:new` task:

```shell
TFT_UNIT=my-app task tft:new
```

The tooling creates each new unit as a copy of the files in `tf/units/template/`. The template directory contains a complete and working TF module for AWS resources. This means that each new unit is immediately ready to use. You are free to change units as you need. For example, you can completely remove the AWS resources from a unit, or have different versions of the same providers in separate units.

The tooling only requires that each unit is a valid TF module with these tfvars:

- `environment_name` (string)
- `product_name` (string)
- `unit_name` (string)
- `edition` (string)

To avoid compatibility issues, I recommend that you use names that only include lowercase letters, numbers and hyphen characters, with the first character being a lowercase letter. Avoid defining environment and edition names that are longer than 7 characters, and unit names that are longer than 12 characters.

> If you amend a module to not use AWS, ensure that you change the tests.

### Contexts

This tooling has _contexts_ to provide profiles for TF. Contexts enable you to deploy multiple instances of the same unit with different configurations, instead of needing to maintain separate sets of code for different instances.

To create a new context, use the `tft:context:new` task:

```shell
TFT_CONTEXT=dev task tft:context:new
```

Each context is a subdirectory in the directory `tf/contexts/` that contains a `context.json` file and one `.tfvars` file per unit.

The `context.json` file is the configuration file for the context. It specifies metadata and settings for TF [remote state](https://opentofu.org/docs/language/state/remote/). Each `context.json` file specifies two items of metadata:

- `description`
- `environment`

The `description` is deliberately not used by the tooling, so that you can leave it empty, or do whatever you wish with it. The `environment` is a string that is automatically provided to TF as the tfvar `environment_name`. There are no limitations on how your code uses this tfvar.

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

The tooling creates each new context as a copy of files in `tf/contexts/template/`. It copies the `standard.tfvars` file to create the tfvars files that are created for new units.

To avoid issues, I recommend that you use context names that only include lowercase letters, numbers and hyphen characters, with the first character being a lowercase letter. Avoid defining context names that are longer than 12 characters.

> Contexts exist to configure TF. To avoid coupling live resources directly to individual contexts, the tooling does not pass the name of the active context to the TF code, only the `environment` name that it specifies.

### Extra Instances

TF has two different ways to create extra copies of the same infrastructure from a root module: the [test](https://opentofu.org/docs/cli/commands/test/) feature and [workspaces](https://opentofu.org/docs/language/state/workspaces/).

The test feature destroys the resources at the end of each test run. The state information about the resources is only held in the memory of the system. This means that it is not stored and no existing state data is updated.

Workspaces means that TF creates a new, separate state for the extra copy, so that you can maintain and update an extra copy for as long as you need it. We often use workspaces to deploy separate copies of infrastructure for development and testing, with different copies from features branches of the same code.

However, if you try to create multiple instances of the same infrastructure from the same root module with the same configuration then it will probably fail. TF will try to create new resources that use exactly the same attributes as the resources for the first copy. The provider will then receive requests from TF to create resources that have the same names as existing resources, and it is likely to handle the problem by refusing to create these new resources.

This tooling implements both TF test and workspaces features with a consistent means of ensuring that every copy of infrastructure can have unique names. It simply defines that every module has a tfvar called `edition`.

This ensures that every instance has an identifier that you can use in your TF code. You include the `edition` identifier in resource names to avoid conflicts between copies. For convenience, the template TF code provides locals that you can use to create unique resource names. The [next section](#managing-resource-names) has more details about resource names.

For workspaces, the tooling automatically sets the value of the tfvar `edition` to match the variable `TFT_EDITION`. Set this variable in any way that you want. For example, you can configure your CI system to set the variable to match branch names. If you do not specify a edition identifier, TF uses the default workspace for state, and the value of the tfvar `edition` is `default`.

For tests, we should use a unique identifier per test run. The test in the unit template includes code to set the value of `edition` to a random string with the prefix `tt`, so that every test copy of infrastructure will have a unique value for the `edition` tfvar.

If you follow this example in your own test code and have used the tfvar `edition` in resource names then you can run tests and create multiple extra instances of infrastructure in parallel without issues.

### Managing Resource Names

Use the `environment`, `unit_name` and `edition` tfvars in your TF code to define resource names that are both meaningful to humans and unique for each instance of the resource. This avoids conflicts between copies of infrastructure.

For convenience, the code in the unit template includes locals and outputs to help with this:

- `tft_handle` - Normalizes the `unit_name` to the first 12 characters, in lowercase
- `tft_standard_prefix` - Combines `environment`, `edition` and `tft_handle`, separated by hyphens

To avoid compatibility issues, I recommend that you use names that only include lowercase letters, numbers and hyphen characters, with the first character being a lowercase letter. Avoid defining environment and edition names that are longer than 7 characters, and unit names that are longer than 12 characters.

To ensure that the template code is compatible with older versions of Terraform, it currently does not use validations on the tfvars.

> The test in the unit template includes code to set the value of the tfvar `edition` to a random string with the prefix `tt`. If you use the `edition` in resource names, this ensures that test copies of resources do not conflict with existing resources that were deployed with the same TF module.

### Shared Modules

The project structure also includes a `tf/shared/` directory to hold TF modules that are shared between the root modules in the same project. By design, the tooling does not manage any of these shared modules, and does not impose any requirements on them.

To share modules between projects, [publish them to a registry](https://opentofu.org/docs/language/modules/#published-modules).

### Dependencies Between Units

By design, this tooling does not specify or enforce any dependencies between infrastructure components. If you need to execute changes in a particular order, specify that order in whichever system you use to carry out deployments.

> This tooling does not explicitly support or conflict with the [stacks feature of Terraform](https://developer.hashicorp.com/terraform/language/stacks). I do not currently test with the stacks feature. It is unclear when this feature will be finalised, or if an equivalent will be implemented by OpenTofu.

### Working with TF Versions

By design, this tooling uses the copy of Terraform or OpenTofu that you provide. It does not install or manage copies of Terraform and OpenTofu, and it is not dependent on specific versions of these tools.

You will need to use different versions of Terraform and OpenTofu for different projects. To handle this, use a tool version manager. The version manager will install the versions that you need and automatically switch between them as needed. Consider using [tenv](https://tofuutils.github.io/tenv/), which is a version manager that is specifically designed for TF tools. For projects that use multiple technologies, consider using [mise](https://mise.jdx.dev/), which can manage versions of many tools and programming languages.

The generated projects include a `.terraform-version` file so that your tool version manager installs and use the Terraform version that you specify. To use OpenTofu, add an `.opentofu-version` file to enable your tool version manager to install and use the OpenTofu version that you specify.

> This tooling can [switch between Terraform and OpenTofu](#using-opentofu). This is specifically to help you migrate projects from one of these tools to the other.

## Install

This project uses several command-line tools. We can install all of these tools on Linux or macOS with [Homebrew](https://brew.sh/):

- [Git](https://git-scm.com/) - `brew install git`
- [Task](https://taskfile.dev) - `brew install go-task`
- [pipx](https://pipx.pypa.io/) OR [uv](https://docs.astral.sh/uv/) - `brew install pipx` OR `brew install uv`

> Set up [shell completions](https://taskfile.dev/installation/#setup-completions) for Task after you install it. Task supports bash, zsh, fish and PowerShell.

The helpers [pipx](https://pipx.pypa.io/) and [uv](https://docs.astral.sh/uv/) enable us to run [Copier](https://copier.readthedocs.io/en/stable/) without installing it:

```shell
pipx run copier copy git+https://github.com/stuartellis/tf-tasks my-project
```

```shell
uvx copier copy git+https://github.com/stuartellis/tf-tasks my-project
```

You can install Terraform or OpenTofu any way that you wish. I recommend that you use [tenv](https://tofuutils.github.io/tenv/). The `tenv` tool automatically installs and uses the required version of Terraform or OpenTofu for the project. If _cosign_ is present, _tenv_ uses it to carry out signature verification on OpenTofu binaries.

```shell
# Install tenv with cosign
brew install tenv cosign
```

The tasks do not use Python or Copier. They only need a UNIX shell, Git, Task and Terraform or OpenTofu. This means that they can be run in a restricted environment, such as a continuous integration job. We can [add tenv to any environment](https://tofuutils.github.io/tenv/#installation) and then use it to install Terraform or OpenTofu.

## Usage

To use the tasks in a generated project you always need:

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

| Name          | Description                                                                                |
| ------------- | ------------------------------------------------------------------------------------------ |
| tft:apply     | _terraform apply_ for a unit\*                                                             |
| tft:check-fmt | Checks whether _terraform fmt_ would change the code for a unit                            |
| tft:clean     | Remove the generated files for a unit                                                      |
| tft:console   | _terraform console_ for a unit\*                                                           |
| tft:destroy   | _terraform apply -destroy_ for a unit\*                                                    |
| tft:fmt       | _terraform fmt_ for a unit                                                                 |
| tft:forget    | _terraform workspace delete_\*                                                             |
| tft:init      | _terraform init_ for a unit. An alias for `tft:init:s3`.                                   |
| tft:new       | Add the source code for a new unit. Copies content from the _tf/units/template/_ directory |
| tft:plan      | _terraform plan_ for a unit\*                                                              |
| tft:rm        | Delete the source code for a unit                                                          |
| tft:test      | _terraform test_ for a unit\*                                                              |
| tft:units     | List the units.                                                                            |
| tft:validate  | _terraform validate_ for a unit\*                                                          |

\*: These tasks require that you first [initialise](https://opentofu.org/docs/cli/commands/init/) the unit.

### The `tft:context` Tasks

| Name             | Description                                                                  |
| ---------------- | ---------------------------------------------------------------------------- |
| tft:context      | An alias for `tft:context:list`.                                             |
| tft:context:list | List the contexts                                                            |
| tft:context:new  | Add a new context. Copies content from the _tf/contexts/template/_ directory |
| tft:context:rm   | Delete the directory for a context                                           |

### The `tft:init` Tasks

| Name           | Description                                               |
| -------------- | --------------------------------------------------------- |
| tft:init       | _terraform init_ for a unit. An alias for `tft:init:s3`.  |
| tft:init:local | _terraform init_ for a unit, with local state.            |
| tft:init:s3    | _terraform init_ for a unit, with Amazon S3 remote state. |

### Settings for Features

Set these variables to override the defaults:

- `TFT_PRODUCT_NAME` - The name of the project
- `TFT_CLI_EXE` - The Terraform or OpenTofu executable to use
- `TFT_REMOTE_BACKEND` - Set to _false_ to force the use of local TF state
- `TFT_EDITION` - See the section on [extra instances](#extra-instances)

### Updating TF Tasks

To update projects with the latest version of this template, use the [update feature of Copier](https://copier.readthedocs.io/en/stable/updating/):

```shell
cd my-project
uvx copier update -A -a .copier-answers-tf-task.yaml .
```

This synchronizes the files in your project that the template manages with the latest release of the template.

> Copier only changes the files and directories that are managed by the template.

### Using Extra Instances

Specify `TFT_EDITION` to create an [extra instance](#extra-instances) of a unit:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app TFT_EDITION=feature1
task tft:plan
task tft:apply
```

Each instance of a unit has an identical configuration as other instances that use the specified context, apart from the tfvar `edition`. The tooling automatically sets the value of the tfvar `edition` to match `TFT_EDITION`. This ensures that every edition has a unique identifier that can be used in TF code.

Only set `TFT_EDITION` when you want to create an extra copy of a unit. If you do not specify a edition identifier, TF uses the default workspace for state, and the value of the tfvar `edition` is `default`.

Once you no longer need the extra instance, run `tft:destroy` to delete the resources, and then run `tft:forget` to delete the TF remote state for the extra instance:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app TFT_EDITION=copy2
task tft:destroy
task tft:forget
```

### Testing

This tooling supports the [validate](https://opentofu.org/docs/cli/commands/validate/) and [test](https://opentofu.org/docs/cli/commands/test/) features of TF. Each unit includes a minimum test configuration, so that you can run immediately run tests on the module as soon as it is created.

A test creates and then immediately destroys resources without storing the state. To ensure that temporary test copies of units do not conflict with other copies of the resources, the test in the unit template includes code to set the value of `edition` to a random string with the prefix `tt`.

To validate a unit before any resources are deployed, use the `tft:validate` task:

```shell
TFT_UNIT=my-app task tft:validate
```

To run tests on a unit, use the `tft:test` task:

```shell
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:test
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

By default, this tooling uses the copy of Terraform that is found on your `PATH`. Set `TFT_CLI_EXE` as an environment variable to specify the path to the tool that you wish to use. For example, to use [OpenTofu](https://opentofu.org/), set `TFT_CLI_EXE` with the value `tofu`:

```shell
TFT_CLI_EXE=tofu
```

To specify which version of OpenTofu to use, create a `.opentofu-version` file. This file should contain the version of OpenTofu and nothing else, like this:

```shell
1.9.1
```

> Remember that if you switch between Terraform and OpenTofu, you will need to initialise your unit again, and when you run `apply` it will migrate the TF state. The OpenTofu Website provides [migration guides](https://opentofu.org/docs/intro/migration/), which includes information about code changes that you may need to make.

## Contributing

This tooling was built for my personal use. I will consider suggestions and Pull Requests, but I may decline anything that makes it less useful for my needs. You are welcome to fork [the project](https://github.com/stuartellis/tf-tasks).

Some of the configuration files for this project template are provided by my [project baseline Copier template](https://github.com/stuartellis/copier-sve-baseline). To synchronize a copy of this project template with the baseline template, run these commands:

```shell
cd tf-tasks
copier update -A -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
