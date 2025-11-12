data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.secret_name
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "aws_db_subnet_group" "this" {
  name       = var.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = var.tags
}


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