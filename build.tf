resource "null_resource" "lambda_build_step" {
  triggers = {
    handler      = "${base64sha256(file("code/punkapi_client.py"))}"
    requirements = "${base64sha256(file("code/requirements.txt"))}"
    build        = "${base64sha256(file("code/build.sh"))}"
  }

  provisioner "local-exec" {
    command = "${path.module}/code/build.sh"
  }
}
