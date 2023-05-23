locals {
  providers                   = { for k, v in var.oidc_providers : k => v if v.enabled }
  providers_with_root_targets = { for k, v in local.providers : k => v if v.enable_stack }
  providers_with_ou_targets   = { for k, v in local.providers : k => v if length(v.enabled_org_units) > 0 && v.enable_stackset }

  provider_schema = {
    github = {
      subkey = "repo" # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
    }
    gitlab = {
      subkey = "project_path" # https://docs.gitlab.com/ee/ci/cloud_services/aws/#configure-a-role-and-trust
    }
  }
}

resource "aws_cloudformation_stack" "ci_oidc_provider" {
  for_each = local.providers_with_root_targets

  name = "${each.key}-aws-oidc-provider"

  template_body = templatefile("${path.module}/templates/stackset.yaml.tftpl", {
    platform        = each.key
    provider_domain = each.value.provider_domain
    audience        = each.value.audience
    thumbprints     = each.value.thumbprints
    trusted_projects_refs = flatten([for project in each.value.trusted_projects_refs : [
      [for combo in setproduct(project.paths, project.branches) : format("${local.provider_schema[each.key].subkey}:%s:ref_type:branch:ref:%s", combo[0], combo[1])],
      [for combo in setproduct(project.paths, project.tags) : format("${local.provider_schema[each.key].subkey}:%s:ref_type:tag:ref:%s", combo[0], combo[1])],
    ]])
  })

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

resource "aws_cloudformation_stack_set" "ci_oidc_provider" {
  for_each = local.providers_with_ou_targets

  name = "${each.key}-aws-oidc-provider"

  template_body = templatefile("${path.module}/templates/stackset.yaml.tftpl", {
    platform        = each.key
    provider_domain = each.value.provider_domain
    audience        = each.value.audience
    thumbprints     = each.value.thumbprints
    trusted_projects_refs = flatten([for project in each.value.trusted_projects_refs : [
      [for combo in setproduct(project.paths, project.branches) : format("${local.provider_schema[each.key].subkey}:%s:ref_type:branch:ref:%s", combo[0], combo[1])],
      [for combo in setproduct(project.paths, project.tags) : format("${local.provider_schema[each.key].subkey}:%s:ref_type:tag:ref:%s", combo[0], combo[1])],
    ]])
  })

  capabilities     = ["CAPABILITY_NAMED_IAM"]
  permission_model = "SERVICE_MANAGED"

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }
}

resource "aws_cloudformation_stack_set_instance" "ci_oidc_provider" {
  for_each = local.providers_with_ou_targets

  deployment_targets {
    organizational_unit_ids = [for ou in each.value.enabled_org_units : local.all_org_units[ou].id]
  }

  stack_set_name = aws_cloudformation_stack_set.ci_oidc_provider[each.key].name
}
