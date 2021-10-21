resource "aws_ecr_repository" "ibu_prediction_repository" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"
}
