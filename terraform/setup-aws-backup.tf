data "aws_ssm_parameter" "daily_backup_enabled" {
  name = "/aft/account-request/custom-fields/daily_backup_enabled"
}

data "template_file" "backup_policy_template" {
  template = file("templates/backup_policy.json.tpl")
}

resource "aws_kms_key" "mm_backup_vault_kms" {
  description              = "KMS CMK for AWS BACKUP VAULT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  is_enabled               = true
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  tags                     = {
    "key-for"     = "AWS-BACKUP-VAULT"
  }
}

#ADD an alias to the key
resource "aws_kms_alias" "mm_backup_vault_kms_cmk" {
  name          = "alias/mm_cmk_kms"
  target_key_id = aws_key_key.mm_backup_vault_kms.key_id
}

resource "aws_backup_vault" "backup_vault" {
  name = "mm-backup-vault"
  kms_key_arn  = aws_kms_key.mm_backup_vault_kms.arn
}

module "Daily_Backup_Plan" {
  count                            = data.aws_ssm_parameter.daily_backup_enabled.value ? 1 : 0
  source                           = "./module/aws-backup"
  backup_plan_name                 = "Daily_Backup_Plan"
  backup_rule_Name                 = "Daily_Backup_Plan_Rule"
  backup_vault_name                = aws_backup_vault.backup_vault.name
  backup_role_arn                  = aws_iam_role.backup_role.arn
  selection_tags_keys              = ["daily-backup"]
  backup_schedule_parameter_name   = "daily_backup_schedule"
  backup_retention_days_parameter_name = "daily_backup_retention"
  continous_backup                 = true
}

resource "aws_iam_role" "backup_role" {
  name               = "backup_role"
  assume_role_policy = <<POLICY
{ 
  "Version":  "2012-10-17"
  "Statement": [
    {
      "Action": [sts:AssumeRole],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
       }
    }
  ] 
}
POLICY
}
resource "aws_iam_role_policy_attachment" "backup_role_policy" {
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role        = aws_iam_role.backup_role.name
}

resource "aws_iam_policy" "backup_role_policy" {
  policy = data.template_file.backup_policy_template.rendered
}

resource "aws_iam_role_policy_attachment" "backup_role_policy_ec2_rds" {
  policy = aws_iam_policy.backup_role_policy.arn
  role   = aws_iam_role.backup_role.name
}
  
