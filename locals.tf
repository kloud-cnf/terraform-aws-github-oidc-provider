# For each OU path provided consume and translate into OU IDs
# Each OU can have many children, build a fresh path for each one based on its parent OU
# Result:
# all_org_units = {
#   "root/labs"      = {
#     arn  = "arn:aws:organizations::016272825626:ou/o-ogiqwmf/ou-xyz-foobar"
#     id   = "ou-xyz-gummybear"
#     name = "playground"
#   }
#   "root/workloads/dev" = {
#     arn  = "arn:aws:organizations::016272825626:ou/o-agio31a/ou-xyz-barfoo"
#     id   = "ou-abcd-gummybear2"
#     name = "workloads"
#   }
#   "root/workloads/prod"    = {
#     arn  = "arn:aws:organizations::016272825626:ou/o-jaifj13/ou-xyz-foozybar"
#     id   = "ou-jkf-gummybear22"
#     name = "workloads"
#   }
# }
locals {
  ou_level_1 = { for ou in data.aws_organizations_organizational_units.level_1.children : join("/", ["root", ou.name]) => ou }
  ou_level_2 = merge([for ou_name, ou in data.aws_organizations_organizational_units.level_2 : { for child in ou.children : join("/", [ou_name, child.name]) => child }]...)
  ou_level_3 = merge([for ou_name, ou in data.aws_organizations_organizational_units.level_3 : { for child in ou.children : join("/", [ou_name, child.name]) => child }]...)
  ou_level_4 = merge([for ou_name, ou in data.aws_organizations_organizational_units.level_4 : { for child in ou.children : join("/", [ou_name, child.name]) => child }]...)
  ou_level_5 = merge([for ou_name, ou in data.aws_organizations_organizational_units.level_5 : { for child in ou.children : join("/", [ou_name, child.name]) => child }]...)

  all_org_units = merge(
    local.ou_level_1,
    local.ou_level_2,
    local.ou_level_3,
    local.ou_level_4,
    local.ou_level_5,
  )
}
