resource "aws_security_group" "security_group" {
  count = var.aws_create_security_group ? 1 : 0
  name = var.name
  description = var.security_group_description
  vpc_id      = var.vpc_id
  tags = merge(module.mandatory_tags.tags, var.tags)
  revoke_rules_on_delete = var.revoke_rules_on_delete
  dynamic "ingress" {
    for_each = [for rule in var.ingress : {
      cidr_blocks       = lookup(rule, "cidr_blocks", null) != null  ? lookup(rule, "cidr_blocks") : []
      ipv6_cidr_blocks  = lookup(rule, "ipv6_cidr_blocks", null) != null ? lookup(rule, "ipv6_cidr_blocks") : []
      prefix_list_ids   = lookup(rule, "prefix_list_ids", null) != null ? lookup(rule, "prefix_list_ids") : []
      from_port         = rule.from_port
      protocol          = rule.protocol
      security_groups   = lookup(rule, "security_groups", null) != null ? lookup(rule, "security_groups") : []
      self              = lookup(rule, "self", null) != null ? lookup(rule, "self") : "false"
      to_port           = rule.to_port
      description       = lookup(rule, "description", null) != null ? lookup(rule, "description") : null
    }] 
    content {
      cidr_blocks       = contains(ingress.value.cidr_blocks,"0.0.0.0/0") ? ["The cidr block 0.0.0.0/0 is not allowed"] : ingress.value.cidr_blocks
      ipv6_cidr_blocks  = contains(ingress.value.ipv6_cidr_blocks,"::/0") ? ["the cidr block ::/0 is not allowed"] : ingress.value.ipv6_cidr_blocks
      prefix_list_ids   = ingress.value.prefix_list_ids
      from_port         = contains([445,80],ingress.value.from_port) == true  ? "The port 445, 80 is not allowed" : ingress.value.from_port 
      protocol          = contains(["http"], lower(ingress.value.protocol) ) == true ? "The HTTP protocol is not allowed" : ingress.value.protocol
      security_groups   = ingress.value.security_groups
      self              = ingress.value.self
      to_port           = contains([445,80],ingress.value.to_port) == true  ? "The port 445,80 is not allowed" : ingress.value.to_port
      description       = ingress.value.description
      
    }
  }
    dynamic "egress" {
    
    for_each = [for rule in var.egress : {
      cidr_blocks           = lookup(rule, "cidr_blocks", null) != null ? lookup(rule, "cidr_blocks") : []
      ipv6_cidr_blocks      = lookup(rule, "ipv6_cidr_blocks", null) != null ? lookup(rule, "ipv6_cidr_blocks") : []
      prefix_list_ids       = lookup(rule, "prefix_list_ids", null) != null ? lookup(rule, "prefix_list_ids") : []
      from_port             = rule.from_port
      protocol              = rule.protocol
      security_groups       = lookup(rule, "security_groups", null) != null ? lookup(rule, "security_groups") : []
      self                  = lookup(rule, "self", null) != null ? lookup(rule, "self") : "false"
      to_port               = rule.to_port
      description           = lookup(rule, "description", null) != null ? lookup(rule, "description") : null
    }]
    
    content {
      cidr_blocks       = egress.value.cidr_blocks
      ipv6_cidr_blocks  = egress.value.ipv6_cidr_blocks
      prefix_list_ids   = egress.value.prefix_list_ids
      from_port         = egress.value.from_port
      protocol          = egress.value.protocol
      security_groups   = egress.value.security_groups
      self              = egress.value.self
      to_port           = egress.value.to_port
      description       = egress.value.description
    }

}

}





















