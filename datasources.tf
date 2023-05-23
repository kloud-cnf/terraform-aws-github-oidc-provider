data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_units" "level_1" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

data "aws_organizations_organizational_units" "level_2" {
  for_each = local.ou_level_1

  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_3" {
  for_each = local.ou_level_2

  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_4" {
  for_each = local.ou_level_3

  parent_id = each.value.id
}

data "aws_organizations_organizational_units" "level_5" {
  for_each = local.ou_level_4

  parent_id = each.value.id
}
