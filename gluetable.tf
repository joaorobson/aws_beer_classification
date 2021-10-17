resource "aws_glue_catalog_database" "punk_api_database" {
  name = "punk_api_database"
}

resource "aws_glue_crawler" "s3_crawler" {
  database_name = aws_glue_catalog_database.punk_api_database.name
  schedule      = "cron(0/5 * * * ? *)"
  name          = "s3_crawler"
  role          = aws_iam_role.glue_role.arn
  classifiers   = ["cleaned_data_classifier"]

  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
      Version = 1
    }
  )

  schema_change_policy {
    update_behavior = "LOG"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.cleaned_data_bucket.bucket}"
  }
}

resource "aws_glue_classifier" "cleaned_data_classifier" {
  name = "cleaned_data_classifier"

  csv_classifier {
    contains_header = "ABSENT"
    delimiter       = ","
    header          = ["abv", "ebc", "ibu", "id", "name", "ph", "srm", "target_fg", "target_og"]
    quote_symbol    = "'"
  }
}

resource "aws_iam_role" "glue_role" {
  name               = "glue_role"
  assume_role_policy = data.aws_iam_policy_document.glue-assume-role-policy.json
}

data "aws_iam_policy_document" "glue-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "glue-extra-policy" {
  name   = "extra-policy"
  policy = data.aws_iam_policy_document.glue-extra-policy-document.json

}

data "aws_iam_policy_document" "glue-extra-policy-document" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:GetBucketAcl",
    "s3:GetObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cleaned_data_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.cleaned_data_bucket.bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "glue-extra-policy-attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue-extra-policy.arn
}


resource "aws_iam_role_policy_attachment" "glue-service-role-attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = data.aws_iam_policy.AWSGlueServiceRole.arn
}

data "aws_iam_policy" "AWSGlueServiceRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
