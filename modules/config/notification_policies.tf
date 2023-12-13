resource "opsgenie_notification_policy" "this" {
  for_each = module.this.enabled ? { for policy in local.notification_policies : policy.name => policy } : tomap()

  enabled = try(each.value.enabled, true)
  name    = each.value.name

  # Look up our team id by name
  team_id            = opsgenie_team.this[each.value.team_name].id
  policy_description = try(each.value.description, each.value.name)

  filter {
    type = try(each.value.filter.type, "match-all")

    dynamic "conditions" {
      for_each = try(each.value.filter.conditions, [])

      content {
        expected_value = try(conditions.value.expected_value, null)
        field          = try(conditions.value.field, null)
        key            = try(conditions.value.key, null)
        not            = try(conditions.value.not, null)
        operation      = try(conditions.value.operation, null)
        order          = try(conditions.value.order, null)
      }
    }
  }

  time_restriction {
    type = try(local.notification_policy.time_restriction.type, null)

    dynamic "restrictions" {
      for_each = try(local.notification_policy.filter.conditions, [])

      content {
        start_day  = try(conditions.value.start_day, null)
        end_day    = try(conditions.value.end_day, null)
        start_hour = try(conditions.value.start_hour, null)
        end_hour   = try(conditions.value.end_hour, null)
        start_min  = try(conditions.value.start_min, null)
        end_min    = try(conditions.value.end_min, null)
      }
    }
  }

  dynamic "de_duplication_action" {
    for_each = try(local.notification_policy.de_duplication_action, null) != null ? ["true"] : []

    content {
      de_duplication_action_type = local.notification_policy.de_duplication_action.de_duplication_action_type
      count                      = local.notification_policy.de_duplication_action.count

      dynamic "duration" {
        for_each = local.notification_policy.de_duplication_action.de_duplication_action_type == "frequency-based" ? ["true"] : [try(local.notification_policy.de_duplication_action.duration, null)]

        content {
          time_amount = local.notification_policy.de_duplication_action.duration.time_amount
          time_unit   = try(local.notification_policy.de_duplication_action.duration.time_unit, null)
        }
      }

      until_hour   = local.notification_policy.delay_action.delay_option != "for-duration" ? local.notification_policy.delay_action.until_hour : null
      until_minute = local.notification_policy.delay_action.delay_option != "for-duration" ? local.notification_policy.delay_action.until_minute : null
    }
  }

  dynamic "delay_action" {
    for_each = try(local.notification_policy.delay_action, null) != null ? ["true"] : []

    content {
      delay_option = local.notification_policy.delay_action.delay_option

      dynamic "duration" {
        for_each = local.notification_policy.delay_action.delay_option == "for-duration" ? ["true"] : []

        content {
          time_amount = local.notification_policy.delay_action.duration.time_amount
          time_unit   = try(local.notification_policy.delay_action.duration.time_unit, null)
        }
      }

      until_hour   = local.notification_policy.delay_action.delay_option != "for-duration" ? local.notification_policy.delay_action.until_hour : null
      until_minute = local.notification_policy.delay_action.delay_option != "for-duration" ? local.notification_policy.delay_action.until_minute : null
    }
  }

  dynamic "auto_close_action" {
    for_each = try(local.notification_policy.auto_close_action, null) != null ? ["true"] : []

    content {
      duration {
        time_amount = local.notification_policy.auto_close_action.duration.time_amount
        time_unit   = local.notification_policy.auto_close_action.duration.time_unit
      }
    }

  }

}
