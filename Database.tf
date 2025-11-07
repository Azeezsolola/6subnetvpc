#----------------------------Create RDS Subnet group-----------------------------------------------------------
resource "aws_db_subnet_group" "groupdb" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.Privateubnet3.id,aws_subnet.Privateubnet4.id]

  tags = {
    Name = "My_DB_Subnet_Group"
  }
}





#------------------------Restoring RDS Database from snapshot------------------------------------------------------

resource "aws_db_instance" "restored_db" {
  identifier          = "wordpressdbclixx-ecs"
  snapshot_identifier = "arn:aws:rds:us-east-1:043309356933:snapshot:wordpressdb"  
  instance_class      = "db.m6gd.large"        
  allocated_storage    = 20                     
  engine             = "mysql"                
  username           = "wordpressuser"
  password           = "W3lcome123"         
  db_subnet_group_name = aws_db_subnet_group.groupdb.name  
  vpc_security_group_ids = [aws_security_group.RDSIngress.id] 
  skip_final_snapshot     = true
  publicly_accessible  = true
  
  tags = {
    Name = "wordpressdb"
  }
}

