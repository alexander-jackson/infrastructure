resource "aws_sns_topic" "notifications" {
  name = "ticket-tracker-notifications"
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = "alexanderjackson@protonmail.com"
}

resource "aws_iam_user" "this" {
  name = "ticket-tracker"
}

resource "aws_iam_access_key" "this" {
  user    = aws_iam_user.this.name
  pgp_key = file("keys/master.key")
}

resource "aws_iam_user_policy" "this" {
  name = format("%s.policy", aws_iam_user.this.name)
  user = aws_iam_user.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}
