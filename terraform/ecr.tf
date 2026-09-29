resource "aws_ecr_repository" "notes_api" {
  name                 = "${var.project}/notes-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # lab

  image_scanning_configuration {
    scan_on_push = true
  }
}
