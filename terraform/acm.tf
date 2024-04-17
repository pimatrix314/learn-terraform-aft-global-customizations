data "aws_caller_identity" "current" {}

data "aws_caller_identity" "aft_management_account" {
  provider = aws.aft_management_account
}

resource "aws_acm_certificate" "mm_acm_vikasshop_public" {
  domain_name                = "vikas.shop"
  subject_alternative_names  = ["*.vikas.shop"]
  validation_method          = "DNS"

lifecycle {
  create_before_destroy = true
}

tags = merge(
  {
     Name = "vikas.shop"
  }
)
}

resource "aws_ssm_parameter" "mm_ssm_acm_vikasshop_public" {
  provider  = aws.aft_management_account_admin
  name      = "mm/acm/${data.aws_caller_identity.current.account_id}/vikasshop_core_domain"
  type      = "StringList"
  value     = join(",", ["CNAME = ${tolist(aws_acm_certificates.mm_acm_vikasshop_public.domain_validation_options)[0]["resource_record_name"]}", "CNAME_VALUE = ${tolist(aws_acm_certificate.mm_acm_vikasshop_public.domain_validation_options)[0]["resource_record_value"]}"])
  overwrite = true
  depends_on = [
      aws_acm_certificate.mm_acm_vikasshop_public
  ]
}
