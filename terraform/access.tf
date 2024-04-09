data "aws_iam_policy" "taccess" {
  name = "AdministratorAccess"
}

data "aws_iam_policy_document" "taccess_assume_role_document" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity"
    ]
    principals {
      type        = "AWS"
      identifiers =  ["arn:aws:iam::211125643431:user/lzadmin"]
    }
  }
}

resource "aws_iam_role" "taccess_assume_role" {
  name                =  "taccess"
  assume_role_policy  = data.aws_iam_policy_document.taccess_assume_role_document.json
  managed_policy_arns = [data.aws_iam_policy.taccess.arn]
  tags = {
    created-by    = "Vikas Dubey"
    }
}
