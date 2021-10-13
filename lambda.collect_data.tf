data "archive_file" "collect_data" {
  type        = "zip"
  source_dir  = "${path.module}/code/collect_data/"
  output_path = "${path.module}/code/collect_data/collect_data.zip"

  depends_on = [null_resource.lambda_build_step]
}

resource "aws_lambda_function" "collect_data" {
  role             = aws_iam_role.iam_for_data_collection.arn
  handler          = "main.retrieve_random_beer_data"
  runtime          = "python3.9"
  filename         = data.archive_file.collect_data.output_path
  function_name    = "get_beer_data"
  source_code_hash = data.archive_file.collect_data.output_base64sha256
}

resource "aws_iam_role" "iam_for_data_collection" {
  name = "iam_for_data_collection"

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

data "aws_iam_policy_document" "data_collection_policy_doc" {
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


resource "aws_iam_policy" "data_collection_policy" {
  name   = "data_collection_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.data_collection_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_data_collection_policy_to_data_collection_role" {
  role       = aws_iam_role.iam_for_data_collection.name
  policy_arn = aws_iam_policy.data_collection_policy.arn
}
