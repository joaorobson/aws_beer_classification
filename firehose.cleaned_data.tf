resource "aws_kinesis_firehose_delivery_stream" "cleaned_data_firehose" {
  name        = "send_cleaned_data_to_s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.data_stream.arn
    role_arn           = aws_iam_role.cleaned_data_firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.cleaned_data_firehose_role.arn
    bucket_arn = aws_s3_bucket.cleaned_data_bucket.arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.clean_data.arn}:$LATEST"
        }
      }
    }
  }
}


resource "aws_s3_bucket" "cleaned_data_bucket" {
  bucket = "cleaned-data-from-punkapi"
  acl    = "private"
}

resource "aws_iam_role" "cleaned_data_firehose_role" {
  name = "cleaned_data_firehose_role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "firehose.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}


data "aws_iam_policy_document" "cleaned_data_firehose_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["kinesis:*"]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::cleaned-data-from-punkapi",
      "arn:aws:s3:::cleaned-data-from-punkapi/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
    ]
    resources = ["arn:aws:lambda:*:*:function:clean_beer_data:*"]
  }

}

resource "aws_iam_policy" "cleaned_data_firehose_policy" {
  name   = "cleaned_data_firehose_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.cleaned_data_firehose_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_cleaned_data_firehose_policy_to_cleaned_data_firehose_role" {
  role       = aws_iam_role.cleaned_data_firehose_role.name
  policy_arn = aws_iam_policy.cleaned_data_firehose_policy.arn
}
