locals {
  providers                   = { for k, v in var.oidc_providers : k => v if v.enabled }
  providers_with_root_targets = { for k, v in local.providers : k => v if v.enable_stack }
  providers_with_ou_targets   = { for k, v in local.providers : k => v if length(v.enabled_org_units) > 0 && v.enable_stackset }

  // Platform specific formatting
  platform_config = {
    // Github -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    // repo:<orgName/repoName>:ref:refs/heads/<branchName>  -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-a-specific-branch
    // repo:<orgName/repoName>:ref:refs/tags/<tagName>      -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-a-specific-tag
    // repo:<orgName/repoName>:pull_request                 -> https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-pull_request-events
    github = {
      trusted_projects_refs = flatten([for project in local.providers["github"].trusted_projects_refs : [
        [for path in project.paths : format("repo:%s:pull_request", path) if project.pull_request],
        [for combo in setproduct(project.paths, project.branches) : format("repo:%s:ref:refs/heads/%s", combo[0], combo[1])],
        [for combo in setproduct(project.paths, project.tags) : format("repo:%s:ref:refs/tags/%s", combo[0], combo[1])],
      ]])
    }

    // Gitlab -> https://docs.gitlab.com/ee/ci/cloud_services/index.html#configure-a-conditional-role-with-oidc-claims
    // project_path:{group}/{project}:ref_type:{type}:ref:{branch_name||tag_name}
    // project_path:mygroup/myproject:ref_type:branch:ref:main
    // project_path:mygroup/myproject:ref_type:tag:ref:v1.0.0
    gitlab = {
      trusted_projects_refs = flatten([for project in local.providers["gitlab"].trusted_projects_refs : [
        [for combo in setproduct(project.paths, project.branches) : format("project_path:%s:ref_type:branch:ref:%s", combo[0], combo[1])],
        [for combo in setproduct(project.paths, project.tags) : format("project_path:%s:ref_type:tag:ref:%s", combo[0], combo[1])],
      ]])
    }
  }
}

resource "aws_cloudformation_stack" "ci_oidc_provider" {
  for_each = local.providers_with_root_targets

  name = "${each.key}-aws-oidc-provider"

  template_body = templatefile("${path.module}/templates/stackset.yaml.tftpl", {
    platform              = each.key
    provider_domain       = each.value.provider_domain
    audience              = each.value.audience
    thumbprints           = each.value.thumbprints
    trusted_projects_refs = local.platform_config[each.key].trusted_projects_refs
  })

  capabilities = ["CAPABILITY_NAMED_IAM"]
}

resource "aws_cloudformation_stack_set" "ci_oidc_provider" {
  for_each = local.providers_with_ou_targets

  name = "${each.key}-aws-oidc-provider"

  template_body = templatefile("${path.module}/templates/stackset.yaml.tftpl", {
    platform              = each.key
    provider_domain       = each.value.provider_domain
    audience              = each.value.audience
    thumbprints           = each.value.thumbprints
    trusted_projects_refs = local.platform_config[each.key].trusted_projects_refs
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
