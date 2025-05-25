resource "aws_sns_topic" "expense_analysis_completions" {
  name = "expense-analysis-completions"
}

resource "aws_sqs_queue" "expense_analysis_completions" {
  name = "expense-analysis-completions"
}

resource "aws_sns_topic_subscription" "expense_analysis_completions" {
  topic_arn = aws_sns_topic.expense_analysis_completions.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.expense_analysis_completions.arn
}
