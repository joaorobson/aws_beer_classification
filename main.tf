terraform {
  required_providers {
    archive = "~> 1.3"
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/services/punkapi_client.py"
  output_path = "${path.module}/services/punkapi_client.py.zip"
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires a request to punk API every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "get_random_beer_data_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.punk_api_request.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_get_beer_data" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.punk_api_request.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}

resource "aws_lambda_function" "punk_api_request" {
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "punkapi_client.retrieve_random_beer_data"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda.output_path
  function_name    = "get_beer_data"
  source_code_hash = base64sha256(filebase64(data.archive_file.lambda.output_path))
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

