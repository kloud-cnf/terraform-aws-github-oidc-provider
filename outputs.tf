# output "ci_oidc_provider_stack_set_names" {
#   description = "Names of the stack sets for CI OIDC providers"
#   value       = [for k, _ in local.providers_with_ou_targets : aws_cloudformation_stack_set_instance.ci_oidc_provider[k]]
# }

# output "ci_oidc_provider_stack_set_instance_ids" {
#   description = "IDs of the stack set instances for CI OIDC providers"
#   value       = [for k, _ in local.providers_with_ou_targets : aws_cloudformation_stack_set_instance.ci_oidc_provider[k].id]
# }
