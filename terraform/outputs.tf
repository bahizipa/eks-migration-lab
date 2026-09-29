output "region" { value = var.region }
output "cluster_name" { value = module.eks.cluster_name }
output "ecr_repository_url" { value = aws_ecr_repository.notes_api.repository_url }
output "rds_endpoint" { value = aws_db_instance.notes.address }
output "db_secret_name" { value = aws_secretsmanager_secret.db.name }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
