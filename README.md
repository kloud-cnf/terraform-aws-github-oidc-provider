# terraform-aws-github-oidc-provider

![](https://img.shields.io/badge/Terraform-1.5x-623CE4?logo=terraform)

> Terraform module to manage IAM OIDC Provider for Github with an entrypoint IAM role 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [Description](#description)
- [Usage](#usage)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---
## Description

This Terraform module provides an automated solution for deploying [OpenID Connect (OIDC) providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) for CI platforms in AWS using [CloudFormation](https://aws.amazon.com/cloudformation/) stacks and stack sets. It currently supports `GitHub` and `GitLab` and allows deployment to individual AWS accounts or organizational units (OUs) within the AWS Organization.

The [template](./templates/stackset.yaml.tftpl) includes the following resources:

1. `OIDCProvider`: This resource provisions an IAM OIDC Provider, configuring essential properties such as the client ID, thumbprint list, URL, and tags.
2. `CIRoleProvisioner`: This resource sets up an IAM Role specifically designed for CI role provisioning. The role comes with a descriptive name, a maximum session duration, and an AssumeRolePolicyDocument that grants the OIDC Provider the ability to assume the role. Additionally, two policies are attached to the role:
   1. `iam-administrate` This policy provides comprehensive administrative permissions for IAM resources, allowing operations like role creation, modification, deletion, policy management, and OIDC Provider management. It also grants access to both account-owned and AWS-managed policies.
   2. `terraform` This policy grants the necessary permissions for managing DynamoDB tables and S3 buckets related to Terraform state storage.

---

## Usage

Define OIDC providers with module inputs

```hcl
...

terraform {
  source = "git::https://github.com/kloud-cnf/terraform-aws-ci-role-provisioner//?ref=v0.1.0"
}

inputs = {
  oidc_providers = {
    github = { # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#adding-the-identity-provider-to-aws
      enabled = true
      provider_domain     = "token.actions.githubusercontent.com"
      audience            = "sts.amazonaws.com"
      thumbprints         = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
      enabled_org_units = [
        "root/labs",
        "root/workloads",
      ]
      trusted_projects_refs = [
        {
          paths = ["<username>/aws-ci-roles"] # Centralized repo on github to manage AWS CI roles
          branches = ["*"]
          tags = ["*"]
        }
      ]
    },
    gitlab = { # https://docs.gitlab.com/ee/ci/cloud_services/aws/#add-the-identity-provider
      enabled = false
      thumbprints         = ["b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a"]
      provider_domain     = "gitlab.com"
      audience            = "https://gitlab.com"
      enabled_org_units = [
        "root/labs",
        "root/workloads",
      ]
      trusted_projects_refs = [
        {
          paths = ["<username>/aws-ci-roles"] # Centralized repo on gitlab to manage AWS CI roles
          branches = ["*"]
          tags = ["*"]
        }
      ]
    }
  }
}
```

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.ci_oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack_set.ci_oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.ci_oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_units.level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_organizations_organizational_units.level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_organizations_organizational_units.level_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_organizations_organizational_units.level_4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |
| [aws_organizations_organizational_units.level_5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_units) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_oidc_providers"></a> [oidc\_providers](#input\_oidc\_providers) | OpenID Connect Configuration for CI platforms | <pre>map(object({<br>    enabled         = optional(bool, true) # enable provider<br>    enable_stack    = optional(bool, true) # enable stack for root account<br>    enable_stackset = optional(bool, true) # enable stackset for target `enabled_org_units`<br>    provider_domain = string<br>    audience        = string<br>    trusted_projects_refs = list(object({ # Define repo(s) access to CI provioner role<br>      paths        = list(string)<br>      branches     = optional(list(string), [])<br>      tags         = optional(set(string), [])<br>      pull_request = optional(bool, true) # Allow role to be assumed on PR event, defaults to true, only needed for GitHub<br>    }))<br>    thumbprints       = list(string)<br>    enabled_org_units = optional(list(string), [])<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enabled_provider_stack_names"></a> [enabled\_provider\_stack\_names](#output\_enabled\_provider\_stack\_names) | Stack names for enabled CI OIDC providers |
| <a name="output_enabled_provider_stack_set_names"></a> [enabled\_provider\_stack\_set\_names](#output\_enabled\_provider\_stack\_set\_names) | Stack set names for enabled CI OIDC providers |
| <a name="output_enabled_providers"></a> [enabled\_providers](#output\_enabled\_providers) | Names of currently enabled OIDC providers |
| <a name="output_provider_deployment_targets"></a> [provider\_deployment\_targets](#output\_provider\_deployment\_targets) | A Map of providers each with a list of deployment targets referenced by OU path |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
