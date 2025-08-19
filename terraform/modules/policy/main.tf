
variable "scope_id" { type = string }
variable "enabled"  { type = bool default = false }

# These IDs vary by cloud/region/tenant. Provide via variables if enabling.
variable "policy_ids" {
  type = object({
    deny_public_kv   = string
    deny_public_sql  = string
    deny_public_stg  = string
    deny_public_adf  = string
    require_pe_stg   = string
  })
  default = {
    deny_public_kv   = ""
    deny_public_sql  = ""
    deny_public_stg  = ""
    deny_public_adf  = ""
    require_pe_stg   = ""
  }
}

resource "azurerm_policy_assignment" "deny_public_kv" {
  count                = var.enabled && var.policy_ids.deny_public_kv != "" ? 1 : 0
  name                 = "deny-public-kv"
  scope                = var.scope_id
  policy_definition_id = var.policy_ids.deny_public_kv
}

resource "azurerm_policy_assignment" "deny_public_sql" {
  count                = var.enabled && var.policy_ids.deny_public_sql != "" ? 1 : 0
  name                 = "deny-public-sql"
  scope                = var.scope_id
  policy_definition_id = var.policy_ids.deny_public_sql
}

resource "azurerm_policy_assignment" "deny_public_stg" {
  count                = var.enabled && var.policy_ids.deny_public_stg != "" ? 1 : 0
  name                 = "deny-public-stg"
  scope                = var.scope_id
  policy_definition_id = var.policy_ids.deny_public_stg
}

resource "azurerm_policy_assignment" "deny_public_adf" {
  count                = var.enabled && var.policy_ids.deny_public_adf != "" ? 1 : 0
  name                 = "deny-public-adf"
  scope                = var.scope_id
  policy_definition_id = var.policy_ids.deny_public_adf
}

resource "azurerm_policy_assignment" "require_pe_stg" {
  count                = var.enabled && var.policy_ids.require_pe_stg != "" ? 1 : 0
  name                 = "require-private-endpoint-stg"
  scope                = var.scope_id
  policy_definition_id = var.policy_ids.require_pe_stg
}
