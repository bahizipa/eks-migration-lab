resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds"
  description = "Postgres access from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "notes" {
  identifier        = "${var.project}-pg"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_user
  password = random_password.db.result

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az                = false # lab; prod = true
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}

# Store the connection string where the app (and later External Secrets) can read it.
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project}/database"
  recovery_window_in_days = 0 # lab: allow immediate re-create after destroy
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username     = var.db_user
    password     = random_password.db.result
    host         = aws_db_instance.notes.address
    port         = 5432
    dbname       = var.db_name
    DATABASE_URL = "postgresql://${var.db_user}:${random_password.db.result}@${aws_db_instance.notes.address}:5432/${var.db_name}"
  })
}
