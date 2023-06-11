variable "oidc_providers" {
  type = map(object({
    enabled         = optional(bool, true) # enable provider
    enable_stack    = optional(bool, true) # enable stack for root account
    enable_stackset = optional(bool, true) # enable stackset for target `enabled_org_units`
    provider_domain = string
    audience        = string
    trusted_projects_refs = list(object({ # Define repo(s) access to CI provioner role
      paths        = list(string)
      branches     = optional(list(string), [])
      tags         = optional(set(string), [])
      pull_request = optional(bool, true) # Allow role to be assumed on PR event, defaults to true, only needed for GitHub
    }))
    thumbprints       = list(string)
    enabled_org_units = optional(list(string), [])
  }))

  description = "OpenID Connect Configuration for CI platforms"

  validation {
    condition     = alltrue(flatten([for platform, _ in var.oidc_providers : [contains(["gitlab", "github"], platform)]]))
    error_message = "Only `github` and `github` providers are supported."
  }
  validation {
    condition = alltrue([
      for _, config in var.oidc_providers :
      !startswith(config.provider_domain, "https://")
    ])
    error_message = "Providers domains should not include 'https://'."
  }
  validation {
    condition     = alltrue(flatten([for provider in var.oidc_providers : [for project in provider.trusted_projects_refs : length(project.branches) + length(project.tags) > 0]]))
    error_message = "At least one of `branches` or `tags` must be specified."
  }
}