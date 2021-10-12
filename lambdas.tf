data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/code/"
  output_path = "${path.module}/code.zip"

  depends_on = [null_resource.lambda_build_step]
}

resource "aws_lambda_function" "punk_api_request" {
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "punkapi_client.retrieve_random_beer_data"
  runtime          = "python3.9"
  filename         = data.archive_file.code.output_path
  function_name    = "get_beer_data"
  source_code_hash = data.archive_file.code.output_base64sha256
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
        Action = [
          "sts:AssumeRole",
        ]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["kinesis:PutRecord"]
    resources = ["arn:aws:kinesis:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}


resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
