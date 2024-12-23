module "bucket" {
  source           = "./modules/s3-bucket"
  bucket_name      = "uptime"
  pending_deletion = true
}

resource "aws_sns_topic" "outages" {
  name = "outages"
}

resource "aws_sns_topic_subscription" "outages" {
  topic_arn = aws_sns_topic.outages.arn
  protocol  = "email"
  endpoint  = "alexanderjackson@protonmail.com"
}
