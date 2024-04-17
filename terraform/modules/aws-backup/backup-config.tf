data "aws_ssm_parameter" "backup_schedule" {
  name = "/aft/account-request/custom-fields/${var.backup_schedule_parameter_name}"
}

data "aws_ssm_parameter" "backup_retention" {
  name = "/aft/account-request/custom-fields/${var.backup_retention_days_parameter_name}"
}

resource "aws_backup_plan" "backup_plan_without_copy" {
  name = var.backup_plan_name
  rule {
     rule_name                 = var.Backup_Rule_Name
     target_vault_name         = var.backup_vault_name
     schedule                  = data.aws_ssm_parameter.backup_schedule.value
     start_window              = var.window_start
     completion_window         = var.window_completion
     # enable_continous_backup = true
     enable_continuous_backup  = var.continous_backup
     lifecycle  {
        delete_after = data.aws_ssm_parameter.backup_retention.value
     }
  }
}

resource "aws_backup_selection" "backup_selection" {
  iam_role_arn  = var.backup_role_arn
  name          = "${var.Backup_Rule_Name}-backup_selection"
  plan_id       = aws_backup_plan.backup_plan_without_copy.id
  dynamic "selectiob_tag" {
    for_each  = toset(var.selection_tags_keys)
    content {
       type  = "STRINGEEQUALS"
       key   = selection_tag.value
       value = "true"
    }
}
}
