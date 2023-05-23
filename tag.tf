locals {
  variable_tags = {
    compliance        = var.compliance
    environment       = var.environment
    company           = var.company
    costcenter        = var.costcenter
    owner-department  = var.owner-department
    business-division = var.it-department
    barometer-it      = var.barometer-it-num
    application-name  = var.application
    resource-type     = var.resource-type
    schedule-window   = var.layer
    app-support-dl    = var.application_dl
  }
  validator = {
    for tag in local.required_tags :
    tag.low => lookup(local.variable_tags, tag.up, null) != null ?
    lookup(local.variable_tags, tag.up, null) : lookup(local.variable_tags, tag.low)
  }

  tags = merge(local.validator, var.tags)
}
