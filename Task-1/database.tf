# DB - Security Group
resource "aws_security_group" "db_security_group" {
  name = "mydb1"

  description = "RDS postgres server"
  vpc_id = aws_vpc.main.id

  # Only postgres in
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.app_instance_sg.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "master_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "db_postgres" {
  allocated_storage        = 256 # gigabytes
  backup_retention_period  = 7   # in days
  db_subnet_group_name     = aws_db_subnet_group.db_subnet.name
  engine                   = "postgres"
  engine_version           = "12.4"
  identifier               = "dbpostgres"
  instance_class           = "db.t3.micro"
  multi_az                 = true
  name                     = "test1_db"
  username                 = "dbadmin"
  password                 = random_password.master_password.result
  port                     = 5432
  publicly_accessible      = false
  storage_encrypted        = true
  storage_type             = "gp2"
  vpc_security_group_ids   = [aws_security_group.db_security_group.id]
  skip_final_snapshot      = true
}