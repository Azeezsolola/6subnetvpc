#--------------------------------------------------Creating VPC -------------------------------------------------
resource "aws_vpc" "TerraformVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "TerraformVPC"
  }
}



#------------------------------------------------Creating public subnet 1 --------------------------------------------
resource "aws_subnet" "Publicsubnet1" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Publicsubnet1"
  }
}


#--------------------------------------------Creating Public Subnet 2 ---------------------------------------------------
resource "aws_subnet" "Publicsubnet2" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Publicsubnet2"
  }
}

#----------------------------------------Creating Private subnet 1 -------------------------------------------------------
resource "aws_subnet" "Privateubnet1" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Privatesubnet1"
  }
}


#---------------------------------------Creating Private subnet 2 ---------------------------------------------------------
resource "aws_subnet" "Privateubnet2" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Privatesubnet2"
  }
}

#---------------------------------------Creating Private subnet 3 -----------------------------------------------------------
resource "aws_subnet" "Privateubnet3" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Privatesubnet3"
  }
}


#-----------------------------------Creating Private subnet 4 -----------------------------------------------------------------
resource "aws_subnet" "Privateubnet4" {
  vpc_id     = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Privatesubnet4"
  }
}