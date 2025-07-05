<!--
SPDX-FileCopyrightText: 2025-present Stuart Ellis <stuart@stuartellis.name>

SPDX-License-Identifier: MIT
-->

# Copier Template for TF Tasks

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier) [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit) [![styled with prettier](https://img.shields.io/badge/styled_with-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

This [Copier](https://copier.readthedocs.io/en/stable/) template provides files for a [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) in a [monorepo](https://en.wikipedia.org/wiki/Monorepo).

The tooling uses [Task](https://taskfile.dev) as the task runner for the template and the generated projects. It provides an opinionated configuration for Terraform and OpenTofu. This configuration enables projects to use built-in features of these tools to support:

- Multiple infrastructure components in the same code repository. Each [unit](#units---tf-modules-as-components) is a complete [root module](https://opentofu.org/docs/language/modules/).
- Multiple instances of the same component with [different configurations](#contexts---configuration-profiles)
- [Extra instances](#extra-instances---workspaces-and-tests) of a component for development and testing. Use this to create disposable instances for the branches of your code as you need them.
- [Integration testing](#testing) for every component.
- [Migrating from Terraform to OpenTofu](#using-opentofu). You use the same tasks for both.

> This uses the identifier _TF_ or _tf_ for Terraform and OpenTofu. Both tools accept the same commands and have the same behavior. The tooling itself is just called `tft` in the documentation and code.

## Table of Contents

- [Quick Examples](#quick-examples)
- [Install](#install)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

## Quick Examples

First, install the tools on Linux or macOS with [Homebrew](https://brew.sh/):

```shell
brew install git go-task uv cosign tenv
```

Start a new project:

```shell
# Run Copier with uv to create a new project, and enter your details when prompted
uvx copier copy git+https://github.com/stuartellis/tf-tasks my-project

# Go to the working directory for the project
cd my-project

# Ask tenv to detect and install the correct version of Terraform for the project
tenv terraform install

# Create a configuration and a root module for the project
TFT_CONTEXT=dev task tft:context:new
TFT_UNIT=my-app task tft:new
```

The `tft:new` task creates a [unit](#units---tf-modules-as-components), a complete Terraform root module. Each new root module includes example code for AWS, so that it can work immediately. The context is a [configuration profile](#contexts---configuration-profiles). You only need to set:

1. The AWS IAM role for TF in the module, with the variable `tf_exec_role_arn`
2. Either remote state storage settings in the [context](#contexts---configuration-profiles), OR use [local state](#using-local-tf-state)

You can then start working with your TF module:

```shell
# Set a default context and unit
export TFT_CONTEXT=dev TFT_UNIT=my-app

# Run tasks on the unit with the configuration from the context
task tft:init
task tft:plan
task tft:apply
```

You can always specifically set the unit and context for a task. This example runs the [integration tests](#testing) for the module:

```shell
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:test
```

To create [an extra copy](#extra-instances---workspaces-and-tests) of the resources for a module, set the variable `TFT_EDITION` with a unique name for the copy. This example will deploy an extra instance called `copy2` alongside the main set of resources:

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

Code included in each TF module enables [unique identifiers for resources](#managing-resource-names), so that you can have multiple copies of resources at the same time. The only requirement is that you include `handle` as part of each resource name:

```hcl
resource "aws_dynamodb_table" "example_table" {
  name = "example-${local.handle}"
```

All of the commands are available through [Task](https://www.stuartellis.name/articles/task-runner/). To see a list of the available tasks in a project, enter _task_ in a terminal window:

```shell
task
```

If you set up [shell completions](https://taskfile.dev/installation/#setup-completions) for Task, you will see you suggestions as you type.

## Install

We use Python and Copier when we create and update projects. The tasks only need a UNIX shell, Git, Task and Terraform or OpenTofu. We can install all the tools that we need on Linux or macOS with [Homebrew](https://brew.sh/):

```shell
brew install git go-task uv cosign tenv
```

> Set up [shell completions](https://taskfile.dev/installation/#setup-completions) for Task after you install it. Task supports bash, zsh, fish and PowerShell.

The [tenv](https://tofuutils.github.io/tenv/) tool automatically installs and uses the correct version of Terraform or OpenTofu for each project. We can [add tenv to any environment](https://tofuutils.github.io/tenv/#installation) and then use it to install the versions of Terraform or OpenTofu that we need. It also verifies the copies that it installs, using _cosign_ to carry out signature verification on OpenTofu binaries and GPG for other downloads.

I recommend that you use a Python helper like [uv](https://docs.astral.sh/uv/) or [pipx](https://pipx.pypa.io/) to run [Copier](https://copier.readthedocs.io/en/stable/) without installing it. The `uv` tool can also install a copy of Python if needed. To run Copier with `uv`, use the `uvx` command:

```shell
uvx copier copy git+https://github.com/stuartellis/tf-tasks my-project
```

If you prefer, you can use `pipx` instead of `uv`:

```shell
pipx run copier copy git+https://github.com/stuartellis/tf-tasks my-project
```

> Task and tenv do not rely on Git. Copier, Terraform and OpenTofu all use Git for operations.

## Usage

To use the tasks in a generated project you will need:

- A UNIX shell
- [Git](https://git-scm.com/)
- [Task](https://taskfile.dev)
- [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/)

The TF tasks in the template do not use Python or Copier. This means that they can be run in a restricted environment, such as a continuous integration system.

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

### Settings for Features

Set these variables to override the defaults:

- `TFT_PRODUCT_NAME` - The name of the project
- `TFT_CLI_EXE` - The Terraform or OpenTofu executable to use
- `TFT_REMOTE_BACKEND` - Set to _false_ to force the use of local TF state
- `TFT_EDITION` - Set the identifier for an extra instance with a TF workspace

### The `tft` Tasks

| Name          | Description                                                                                |
| ------------- | ------------------------------------------------------------------------------------------ |
| tft:apply     | _terraform apply_ for a unit\*                                                             |
| tft:check-fmt | Checks whether _terraform fmt_ would change the code for a unit                            |
| tft:clean     | Remove the generated files for a unit                                                      |
| tft:console   | _terraform console_ for a unit\*                                                           |
| tft:context   | An alias for `tft:context:list`.                                                           |
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

### The `tft:instance` Tasks

| Name                | Description                                 |
| ------------------- | ------------------------------------------- |
| tft:instance:handle | Handle for the instance of the TF unit      |
| tft:instance:sha256 | SHA256 hash for the instance of the TF unit |

### The `tft:init` Tasks

| Name           | Description                                                             |
| -------------- | ----------------------------------------------------------------------- |
| tft:init       | _terraform init_ for a unit. An alias for `tft:init:s3ddb`.             |
| tft:init:local | _terraform init_ for a unit, with local state.                          |
| tft:init:s3ddb | _terraform init_ for a unit, with S3 remote state and DynamoDB locking. |

### Using Extra Instances

Specify `TFT_EDITION` to create an [extra instance](#extra-instances---workspaces-and-tests) of a unit:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app TFT_EDITION=feature1
task tft:plan
task tft:apply
```

Each instance of a unit has an identical configuration as other instances that use the specified context, apart from the tfvar `tft_edition`. The tooling automatically sets the value of the tfvar `tft_edition` to match `TFT_EDITION`. This ensures that every edition has a unique identifier that can be used in TF code.

Only set `TFT_EDITION` when you want to create an extra copy of a unit. If you do not specify a edition identifier, TF uses the default workspace for state, and the value of the tfvar `tft_edition` is `default`.

Once you no longer need the extra instance, run `tft:destroy` to delete the resources, and then run `tft:forget` to delete the TF remote state for the extra instance:

```shell
export TFT_CONTEXT=dev TFT_UNIT=my-app TFT_EDITION=copy2
task tft:destroy
task tft:forget
```

### Testing

This tooling supports the [validate](https://opentofu.org/docs/cli/commands/validate/) and [test](https://opentofu.org/docs/cli/commands/test/) features of TF. Each unit includes a test configuration, so that you can run immediately run tests on the module as soon as it is created.

A test creates and then immediately destroys resources without storing the state. To ensure that temporary test copies of units do not conflict with other copies of the resources, the test in the unit template includes code to set the value of `tft_edition` to a random string with the prefix `tt`.

To check whether _terraform fmt_ needs to be run on the module, use the `tft:check-fmt` task:

```shell
TFT_UNIT=my-app task tft:check-fmt
```

If this check fails, run the `tft:fmt` task to format the module:

```shell
TFT_UNIT=my-app task tft:fmt
```

To validate a unit before any resources are deployed, use the `tft:validate` task:

```shell
TFT_UNIT=my-app task tft:validate
```

To run tests on a unit, use the `tft:test` task:

```shell
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:test
```

> Unless you set a test to only _plan_, it will create and destroy copies of resources. Check the expected behaviour of the types of resources that you are managing before you run tests, because cloud services may not immediately remove some resources.

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
1.10.2
```

> Remember that if you switch between Terraform and OpenTofu, you will need to initialise your unit again, and when you run `apply` it will migrate the TF state. The OpenTofu Website provides [migration guides](https://opentofu.org/docs/intro/migration/), which includes information about code changes that you may need to make.

### Updating TF Tasks

To update a project with the latest version of the template, we use the [update feature of Copier](https://copier.readthedocs.io/en/stable/updating/). We can use either [pipx](https://pipx.pypa.io/) or [uv](https://docs.astral.sh/uv/) to run Copier:

```shell
cd my-project
pipx run copier update -A -a .copier-answers-tf-task.yaml .
```

```shell
cd my-project
uvx copier update -A -a .copier-answers-tf-task.yaml .
```

Copier `update` synchronizes the files in the project that the template manages with the latest release of the template.

> Copier only changes the files and directories that are managed by the template.

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

### Units - TF Modules as Components

You define each set of infrastructure code as a component. Every infrastructure component is a separate TF root [module](https://opentofu.org/docs/language/modules/). This means that each component can be created, tested, updated or destroyed independently of the others. This tooling refers to these components as _units_.

To create a new unit, use the `tft:new` task:

```shell
TFT_UNIT=my-app task tft:new
```

Each unit is created as a subdirectory in the directory `tf/units/`.

The tooling only requires that each unit is a valid TF root module that accepts four variables. The provided code implements these in the file `tft_variables.tf`:

- `tft_product_name` (string) - The name of the product or project
- `tft_environment_name` (string) - The name of the environment
- `tft_unit_name` (string) - The name of the component
- `tft_edition` (string) - An identifier for the specific instance of the resources

The tooling sets the values of the required variables when it runs TF commands on a unit:

- `tft_product_name` - Defaults to the name of the project, but you can [override this](#settings-for-features)
- `tft_environment_name` - Provided by the current [context](#contexts---configuration-profiles)
- `tft_unit_name` - The name of the unit itself
- `tft_edition` - Set as the value `default`, except when using an [extra instance](#extra-instances---workspaces-and-tests) or running [tests](#testing)

The provided code for new units has locals that use these variables to help you generate [names and identifiers](#managing-resource-names). These include a `handle`, a short version of a unique SHA256 hash. This means that you can have as many copies of resources as you wish, as long as you use the `handle` as part of each resource name:

```hcl
resource "aws_dynamodb_table" "example_table" {
  name = "example-${local.handle}"
```

> To avoid a direct dependency between your resources and the tooling, only use the required variables in locals. Then use locals to define resource names.

If the default behaviour is not appropriate, you can customise the contents of modules in any way that you need. The tooling automatically finds all of the modules in the directory `tf/units/`. It only requires that each module is a valid TF root module and accepts the four input variables.

> Since each unit is a separate module, you can have different versions of the same providers in separate units.

### Contexts - Configuration Profiles

Contexts enable you to define named configurations for TF. You can then use these to deploy multiple instances of the same unit with different configurations, instead of needing to maintain separate sets of code for different instances. For example, if you have separate AWS accounts for development and production then you can define these as separate contexts.

To create a new context, use the `tft:context:new` task:

```shell
TFT_CONTEXT=dev task tft:context:new
```

Each context is a subdirectory in the directory `tf/contexts/` that contains a `context.json` file and one `.tfvars` file per unit.

The `context.json` file is the configuration file for the context. It specifies metadata and settings for TF [remote state](https://opentofu.org/docs/language/state/remote/). Each `context.json` file specifies two items of metadata:

- `environment`
- `description`

The `environment` is a string that is automatically provided to TF as the tfvar `tft_environment_name`. The `description` is deliberately not used by the tooling, so that you can leave it empty, or do whatever you wish with it.

Here is an example of a `context.json` file:

```json
{
  "metadata": {
    "description": "Cloud development environment",
    "environment": "dev"
  },
  "backend_s3ddb": {
    "tfstate_bucket": "789000123456-tf-state-dev-eu-west-2",
    "tfstate_ddb_table": "789000123456-tf-lock-dev-eu-west-2",
    "tfstate_dir": "dev",
    "region": "eu-west-2",
    "role_arn": "arn:aws:iam::789000123456:role/my-tf-state-role"
  }
}
```

To enable you to have variables for a unit that apply for every context, the directory `tf/contexts/all/` contains one `.tfvars` file for each unit. The `.tfvars` file for a unit in the `tf/contexts/all/` directory is always used, along with `.tfvars` for the current context.

The tooling creates each new context as a copy of files in `tf/contexts/template/`. It copies the `standard.tfvars` file to create the tfvars files for new units. You can actually create and edit the contexts with any method. The tooling will automatically find all of the contexts in the directory `tf/contexts/`.

To avoid compatibility issues between systems, we should use context and environment names that only include lowercase letters, numbers and hyphen characters, with the first character being a lowercase letter. The section on [resource names](#managing-resource-names) provides more guidance.

> Contexts exist to provide configurations for TF. To avoid coupling live resources directly to contexts, the tooling does not pass the name of the active context to the TF code, only the `environment` name that the context specifies.

### Extra Instances - Workspaces and Tests

TF has two different ways to create extra copies of the same infrastructure from a root module: [workspaces](https://opentofu.org/docs/language/state/workspaces/) and [tests](https://opentofu.org/docs/cli/commands/test/). We use workspaces to have multiple sets of resources that are associated with the same root module. These copies might be from different branches of the code repository for the project. The test feature uses _apply_ to create new copies of resources and then automatically runs _destroy_ to remove them at the end of each test run.

The extra copies of resources for workspaces and tests create a problem. If you run the same code with the same inputs TF could attempt to create multiple copies of resources with the same name. Cloud services often refuse to allow you to have multiple resources with identical names. They may also keep deleted resources for a period of time, which prevents you from creating new resources that have the same names as other resources that you have deleted.

To solve this problem, the tooling allows each copy of a set of infrastructure to have a [separate identifier](#ensuring-unique-identifiers-for-instances), regardless of how the copy was created. You can have as many copies of resources as you wish, as long as you use the local `handle` as part of resource names.

#### Ensuring Unique Identifiers for Instances

If you include the local `handle` in all resource names then every resource will have a unique name, and you will not experience naming conflicts.

The tooling allows every copy of a set of infrastructure to have a separate identifier, which is called the _edition_. The edition is always set to the value _default_, unless you [run a test](#testing) or decide to [use an extra instance](#using-extra-instances). The tooling sets the variable `tft_edition` to match the required edition. The template TF code provides a local called `handle` that uses `tft_edition` to provide a short version of a unique SHA256 hash. It also ensures that the full version of this hash is attached to resources as an AWS tag.

A [later section](#managing-resource-names) has more details about working with resource names and instance hashes.

#### Working with Extra Instances

By default, TF works with the main copy of the resources for a module. This means that it uses the `default` workspace.

To work with another copy of the resources, set the variable `TFT_EDITION`. The tooling then sets the active workspace to match the variable `TFT_EDITION` and sets the tfvar `tft_edition` to the same value. If a workspace with that name does not already exist, it will automatically be created. To remove a workspace, first run the `destroy` task to terminate the copy of the resources that it manages, and then run the `forget` task to delete the stored state.

You can set the variable `TFT_EDITION` to any string. For example, you can configure your CI system to set the variable `TFT_EDITION` with values that are based on branch names.

You do not set `TFT_EDITION` for tests. The example test in the unit template includes code to automatically set the value of `tft_edition` to a random string with the prefix `tt`. This is because we need to use a pattern for `tft_edition` that guarantees a unique value for every test run. You can change this to use a different format in the `tft_edition` identifier for your tests.

### Managing Resource Names

Cloud systems use tags or labels to enable you to categorise and manage resources. However, resources often need to have unique names. Every type of cloud resource may have a different set of rules about acceptable names. The tooling uses hashes to provide a `handle` as a local, so that every instance of a unit has a unique prefix that you can use in the resource names.

For consistency and the best compatibility between systems, we should always follow some simple guidelines for identifiers. Values should only include lowercase letters, numbers and hyphen characters, with the first character being a lowercase letter. To avoid limits on the total length of resource names, try to limit the size of the standard identifiers:

- _Product or project name:_ `tft_product_name` - 12 characters or less
- _Component name:_ `tft_unit_name` - 12 characters or less
- _Environment name:_ `tft_environment_name` - 8 characters or less
- _Instance name:_ `tft_edition` - 8 characters or less

To avoid coupling live resources directly to the variables that TFT provides, do not reference these variables directly in resource names. Use these variables in locals, and then use the locals to set resource names. For convenience, the code in the unit template includes locals and outputs that you can use in resource names. These are defined in the file `meta_locals.tf`:

```hcl
locals {

  # Use these in tags and labels
  meta_component_name       = lower(var.tft_unit_name)
  meta_edition              = lower(var.tft_edition)
  meta_environment_name     = lower(var.tft_environment_name)
  meta_product_name         = lower(var.tft_product_name)
  meta_instance_sha256_hash = sha256("${local.meta_product_name}-${local.meta_environment_name}-${local.meta_component_name}-${local.meta_edition}")

  # Use this in resource names
  handle = substr(local.meta_instance_sha256_hash, 0, 8)
}
```

The SHA256 hash in the locals provides a unique identifier for each instance of the root module. This enables us to have a short `handle` that we can use in any kind of resource name. For example, we might create large numbers of Lambdas in an AWS account with different TF root modules, and they will not conflict if the name of each Lambda includes the `handle`.

The tooling includes tasks to show the identifiers for instances, so that you can match deployed resources to the code that produced them:

```shell
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:instance:handle
TFT_CONTEXT=dev TFT_UNIT=my-app task tft:instance:sha256
```

The example code deploys an AWS Parameter Store parameter that has the SHA256 hash, and also attaches an `InstanceSha256` tag to every resource. This enables us to query AWS for resources by instance.

> The test in the unit template includes code to set the value of the variable `tft_edition` to a random string with the prefix `tt`. This means that test copies of resources have unique identifiers and will not conflict with existing resources that were deployed with the same TF module.

### Shared Modules

The project structure includes a `tf/shared/` directory to hold TF modules that are shared between the root modules in the same project. By design, the tooling does not manage any of these shared modules, and does not impose any requirements on them.

To share modules between projects, [publish them to a registry](https://opentofu.org/docs/language/modules/#published-modules).

### Dependencies Between Units

This tooling does not specify or enforce any dependencies between infrastructure components. You are free to run operations on separate components in parallel whenever you believe that this is safe. If you need to execute changes in a particular order, specify that order in whichever system you use to carry out deployments.

Similarly, there are no restrictions on how you run tasks on multiple units. You can use any method that can call Task several times with the required variables. For example, you can create your own Taskfiles that call the supplied tasks, write a script, or define jobs for your CI system.

> This tooling does not explicitly support or conflict with the [stacks feature of Terraform](https://developer.hashicorp.com/terraform/language/stacks). I do not currently test with the stacks feature. It is unclear when this feature will be finalised, or if an equivalent will be implemented by OpenTofu.

### Working with TF Versions

By default, this tooling uses the copy of Terraform or OpenTofu that is provided by the system. It does not install or manage copies of Terraform and OpenTofu. It is also not dependent on specific versions of these tools.

You will need to use different versions of Terraform and OpenTofu for different projects. To handle this, use a tool version manager. The version manager will install the versions that you need and automatically switch between them as needed. Consider using [tenv](https://tofuutils.github.io/tenv/), which is a version manager that is specifically designed for TF tools. Alternatively, you could decide to manage your project with [mise](https://mise.jdx.dev/), which handles all of the tools that the project needs.

The generated projects include a `.terraform-version` file so that your tool version manager installs and use the Terraform version that you specify. To use OpenTofu, add an `.opentofu-version` file to enable your tool version manager to install and use the OpenTofu version that you specify.

> This tooling can [switch between Terraform and OpenTofu](#using-opentofu). This is specifically to help you migrate projects from one of these tools to the other.

## Contributing

This tooling was built for my personal use. I will consider suggestions and Pull Requests, but I may decline anything that makes it less useful for my needs.

Some of the configuration files for this project template are provided by my [project baseline Copier template](https://github.com/stuartellis/copier-sve-baseline). To synchronize a copy of this project template with the baseline template, run these commands:

```shell
cd tf-tasks
copier update -A -a .copier-answers-baseline.yaml .
```

## License

MIT © 2025 Stuart Ellis
