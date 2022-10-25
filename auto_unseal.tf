resource "aws_iam_role" "vault-unseal" {
  name = "vault-unseal"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": var.openid_arn
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${var.openid_url}:sub": "system:serviceaccount:vault:vault"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "vault-unseal" {
  name = "vault-unseal"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:Decrypt",
          "kms:Encrypt"
        ]
        Effect = "Allow"
        Resource = aws_kms_key.vault-unseal.arn
      }
    ]
  })
  depends_on = [
    aws_kms_key.vault-unseal,
  ]
}

resource "aws_iam_policy_attachment" "vault-unseal" {
  name = "vault-unseal"
  policy_arn = aws_iam_policy.vault-unseal.arn
  roles = [ aws_iam_role.vault-unseal.name ]
}

resource "aws_kms_key" "vault-unseal" {
  description = "vault unseal"
  deletion_window_in_days = 7
  enable_key_rotation = true

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "kms:*",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.kms_user}"
       }
    },
    {
      "Action": [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault-unseal"
      },
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOT
}

resource "aws_kms_alias" "vault-unseal" {
  name = "alias/vault-unseal"
  target_key_id = aws_kms_key.vault-unseal.key_id
}
