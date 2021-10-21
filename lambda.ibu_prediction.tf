resource "aws_s3_bucket" "ibu_prediction_bucket" {
  bucket = local.model_bucket_name
  acl    = "private"
}

resource "aws_lambda_function" "ibu_prediction" {
  role          = aws_iam_role.ibu_prediction_role.arn
  function_name = "predict_ibu"
  image_uri     = "${aws_ecr_repository.ibu_prediction_repository.repository_url}:latest"
  package_type  = "Image"

	memory_size = 1024
}

resource "aws_iam_role" "ibu_prediction_role" {
  name = "ibu_prediction_role"

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

data "aws_iam_policy_document" "ibu_prediction_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.model_bucket_name}/*"]
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


resource "aws_iam_policy" "ibu_prediction_policy" {
  name   = "ibu_prediction_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ibu_prediction_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_ibu_prediction_policy_to_ibu_prediction_role" {
  role       = aws_iam_role.ibu_prediction_role.name
  policy_arn = aws_iam_policy.ibu_prediction_policy.arn
}
