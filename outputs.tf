output "enabled_providers" {
  description = "Names of currently enabled OIDC providers"
  value       = [for k, _ in local.providers : k]
}

output "enabled_provider_stack_names" {
  description = "Stack names for enabled CI OIDC providers"
  value       = [for k, _ in local.providers_with_root_targets : aws_cloudformation_stack.ci_oidc_provider[k].name]
}

output "enabled_provider_stack_set_names" {
  description = "Stack set names for enabled CI OIDC providers"
  value       = [for k, _ in local.providers_with_ou_targets : aws_cloudformation_stack_set.ci_oidc_provider[k].name]
}
output "provider_deployment_targets" {
  description = "A Map of providers each with a list of deployment targets referenced by OU path"
  value = { for k, _ in local.providers : k => flatten(
    compact(flatten([
      [var.oidc_providers[k].enable_stack ? lower(data.aws_organizations_organization.org.roots[0].name) : null],
      [
        var.oidc_providers[k].enable_stackset ? [
          for ou_id in aws_cloudformation_stack_set_instance.ci_oidc_provider[k].deployment_targets[0].organizational_unit_ids : [for k, v in local.all_org_units : k if v.id == ou_id]
        ] : []
      ]
      ]
    ))
  ) }
}
