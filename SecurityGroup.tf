#------------------------------------Creating Load Balancer Sg, adding Ingress and outgress Rule to the Load balancer SG ----------------------------
resource "aws_security_group" "LB" {
  name   = var.LoadbalancerSG
  vpc_id = aws_vpc.TerraformVPC.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    cidr_blocks          = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




#---------------------------------Creating Ec2 Insatance Sg, adding Ingress and Outgress Rule for Ec2 Instances -----------------------------------
resource "aws_security_group" "EC2" {
  name   = "EC2SG"
  vpc_id = aws_vpc.TerraformVPC.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.LB.id] # source SG
  }

  ingress {
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_groups          = [aws_security_group.Bastionssh.id] # source SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}







#----------------------------------------Creating ,adding Ingress and outgress Rule for Bastion Sg --------------------------------------------
resource "aws_security_group" "Bastionssh" {
  name   = var.Bastion
  vpc_id = aws_vpc.TerraformVPC.id

  ingress {
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks          = ["0.0.0.0/0"] # From everywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#--------------------------------------Creating and adding Ingress and Outgress Rule for EFS --------------------------------------------------
resource "aws_security_group" "EFSIngress" {
  name   = var.EFS
  vpc_id = aws_vpc.TerraformVPC.id

  ingress {
    from_port                = 2049
    to_port                  = 2049
    protocol                 = "tcp"
    security_groups          = [aws_security_group.EC2.id] # source SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#------------------------------- -------Creating Sg for RDS Databse  -----------------------------------------------------------------
resource "aws_security_group" "RDSIngress" {
  name   = var.RDS
  vpc_id = aws_vpc.TerraformVPC.id

  ingress {
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_groups          = [aws_security_group.EC2.id] # source SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


