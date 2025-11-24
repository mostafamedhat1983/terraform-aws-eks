# ========================================
# Secrets Manager Integration
# ========================================
# Reads database credentials from AWS Secrets Manager
# Bidirectional: Reads credentials, then updates with connection details

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.secret_name
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

# ========================================
# RDS Subnet Group
# ========================================
# Defines which subnets RDS can be deployed in
# Spans multiple AZs for high availability

resource "aws_db_subnet_group" "this" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = var.tags
}

# ========================================
# RDS MySQL Instance
# ========================================
# MySQL database instance with encryption and automated backups
# Dev: Single-AZ, 1-day backups, skip final snapshot
# Prod: Multi-AZ, 7-day backups, timestamped final snapshot

resource "aws_db_instance" "this" {
  identifier           = var.identifier
  storage_type         = var.storage_type
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az            = var.multi_az #false in dev to save costs
  allocated_storage    = var.storage_size
  db_name              = local.db_creds.dbname
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = local.db_creds.username
  password             = local.db_creds.password
  parameter_group_name = var.parameter_group_name
  storage_encrypted = true
  backup_retention_period = var.backup_retention_period 
  skip_final_snapshot  = var.skip_final_snapshot #true in dev for faster deletion
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  tags = var.tags

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# ========================================
# Update Secrets Manager
# ========================================
# Updates secret with RDS connection details (host, port)
# Allows applications to get complete connection info from one secret

resource "aws_secretsmanager_secret_version" "db_credentials_update" {
  secret_id = var.secret_name
  secret_string = jsonencode({
    username = local.db_creds.username
    password = local.db_creds.password
    dbname   = local.db_creds.dbname
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
  })
}