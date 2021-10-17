resource "aws_s3_bucket" "punkapi-data-from-glue" {
  bucket = "punkapi-data-from-glue"
  acl    = "private"
}
