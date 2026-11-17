resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.project}-db-subnets"
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true # encrypted at rest with KMS, so its snapshots are encrypted too

  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true # password is generated and stored in Secrets Manager, never in code

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false # single AZ keeps the lab cheap

  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = {
    Name = "${var.project}-postgres"
  }
}

# Manual snapshot. It is encrypted automatically because the database is encrypted.
resource "aws_db_snapshot" "manual" {
  count = var.create_manual_snapshot ? 1 : 0

  db_instance_identifier = aws_db_instance.postgres.identifier
  db_snapshot_identifier = "${var.project}-manual-snapshot"
}
