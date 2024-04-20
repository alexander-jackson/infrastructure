module "bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "uptime"
}

resource "aws_sns_topic" "outages" {
  name = "outages"
}

resource "aws_sns_topic_subscription" "outages" {
  topic_arn = aws_sns_topic.outages.arn
  protocol  = "email"
  endpoint  = "alexanderjackson@protonmail.com"
}

resource "aws_ecr_repository" "uptime" {
  name                 = "uptime"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_iam_user" "image_builder" {
  name = "image.builder"
}

resource "aws_iam_access_key" "image_builder" {
  user    = aws_iam_user.image_builder.name
  pgp_key = file("keys/pgp-b64.key")
}

resource "aws_iam_user_policy" "image_builder" {
  name = format("%s.policy", aws_iam_user.image_builder.name)
  user = aws_iam_user.image_builder.name

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
        Resource = aws_ecr_repository.uptime.arn
      },
      {
        Action   = ["ecr:GetAuthorizationToken"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "uptime" {
  name               = "uptime"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "uptime" {
  name        = format("uptime-policy")
  description = format("Policy for uptime")

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = module.bucket.arn
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = format("%s/*", module.bucket.arn)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "uptime" {
  role       = aws_iam_role.uptime.name
  policy_arn = aws_iam_policy.uptime.arn
}

locals {
  uptime_tag = "20240420-1947"
}

resource "aws_lambda_function" "uptime" {
  function_name = "uptime"
  image_uri     = format("%s:%s", aws_ecr_repository.uptime.repository_url, local.uptime_tag)
  package_type  = "Image"

  role          = aws_iam_role.uptime.arn
  architectures = ["x86_64"]
  description   = "Monitors uptime for a given URI"

  environment {
    variables = {
      TARGET_URI   = "https://opentracker.app"
      STATE_BUCKET = module.bucket.name
      STATE_KEY    = "state.json"
    }
  }
}

data "aws_iam_policy_document" "uptime_trigger_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "uptime_trigger" {
  name               = "uptime-trigger"
  assume_role_policy = data.aws_iam_policy_document.uptime_trigger_assume_role.json
}

resource "aws_iam_policy" "uptime_trigger" {
  name        = "uptime-trigger"
  description = "Policy for uptime-trigger-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.uptime.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "uptime_trigger" {
  role       = aws_iam_role.uptime_trigger.name
  policy_arn = aws_iam_policy.uptime_trigger.arn
}

resource "aws_scheduler_schedule" "uptime" {
  name                = "uptime-trigger"
  schedule_expression = "rate(1 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.uptime.arn
    role_arn = aws_iam_role.uptime_trigger.arn
  }
}
