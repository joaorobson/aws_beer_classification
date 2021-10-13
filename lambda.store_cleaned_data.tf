data "archive_file" "clean_data" {
  type        = "zip"
  source_file = "${path.module}/code/clean_data/main.py"
  output_path = "${path.module}/code/clean_data/clean_data.zip"
}

resource "aws_lambda_function" "clean_data" {
  role             = aws_iam_role.iam_for_data_cleaning.arn
  handler          = "main.clean_data"
  runtime          = "python3.9"
  filename         = data.archive_file.clean_data.output_path
  function_name    = "clean_beer_data"
  source_code_hash = data.archive_file.clean_data.output_base64sha256
}

resource "aws_iam_role" "iam_for_data_cleaning" {
  name = "iam_for_data_cleaning"

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

data "aws_iam_policy_document" "data_cleaning_policy_doc" {
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


resource "aws_iam_policy" "data_cleaning_policy" {
  name   = "lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.data_cleaning_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_data_cleaning_policy_to_data_cleaning_role" {
  role       = aws_iam_role.iam_for_data_cleaning.name
  policy_arn = aws_iam_policy.data_cleaning_policy.arn
}
