resource "null_resource" "lambda_build_step" {
  triggers = {
    handler      = "${base64sha256(file("code/collect_data/main.py"))}"
    requirements = "${base64sha256(file("code/collect_data/requirements.txt"))}"
    build        = "${base64sha256(file("code/collect_data/install_dependencies.sh"))}"
  }

  provisioner "local-exec" {
    command = "${path.module}/code/collect_data/install_dependencies.sh"
  }
}
