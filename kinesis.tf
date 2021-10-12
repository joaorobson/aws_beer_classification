resource "aws_kinesis_stream" "data_stream" {
  name        = "data_distributor"
  shard_count = 1

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}

resource "aws_kinesis_firehose_delivery_stream" "raw_data_stream" {
  name        = "raw_data_to_s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.data_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw_data_bucket.arn
  }
}

resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "raw-data-from-punkapi"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_role"

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


data "aws_iam_policy_document" "firehose_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["kinesis:*"]
    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::raw-data-from-punkapi",
      "arn:aws:s3:::raw-data-from-punkapi/*"
    ]
  }
}

resource "aws_iam_policy" "firehose_policy" {
  name   = "firehose_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.firehose_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_firehose_policy_to_firehose_role" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

