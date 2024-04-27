resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_iam_user" "builder" {
  name = format("%s-builder", var.name)
}

resource "aws_iam_access_key" "builder" {
  user    = aws_iam_user.builder.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "builder" {
  name = format("%s-policy", aws_iam_user.builder.name)
  user = aws_iam_user.builder.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.this.arn
      },
      {
        Action   = ["ecr:GetAuthorizationToken"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
