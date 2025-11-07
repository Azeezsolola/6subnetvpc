#------------------------------------Creating Internet Gateway ------------------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.TerraformVPC.id

  tags = {
    Name = "InternetGW"
  }
}



#----------------------------------Getting the Public subnet Id for the NAT -------------------------------------------------------------
data "aws_subnet" "selectedSubnet" {
  filter {
    name   = "tag:Name"
    values = ["Publicsubnet1"]
  }
  depends_on = [ aws_subnet.Publicsubnet1 ]
}


#----------------------------------Getting Elastic IP for NAT --------------------------------------------------------------
data "aws_eip" "NATEIP1" {
  filter {
    name   = "tag:Name"
    values = ["NATEIP"]
  }
}
output "eip_address" {
  value = data.aws_eip.NATEIP1.id
  description = "Elastic IP to be attached to NAT"
}

#-----------------------------Creating NAT ---------------------------------------------------------------------
resource "aws_nat_gateway" "example" {
  allocation_id = data.aws_eip.NATEIP1.id
  subnet_id     = data.aws_subnet.selectedSubnet.id

  tags = {
    Name = "NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}


#-----------------------------------Creating Public Route Table -------------------------------------------------------
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.TerraformVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}


#----------------------------------Attaching Route table to Public Subnet ------------------------------------------
resource "aws_route_table_association" "a" {
  subnet_id      = data.aws_subnet.selectedSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}


#----------------------------------------Getting info for the second Public Subnet ------------------------------------------
data "aws_subnet" "selectedSubnet2" {
  filter {
    name   = "tag:Name"
    values = ["Publicsubnet2"]
  }
  depends_on = [ aws_subnet.Publicsubnet2 ]
}


#---------------------------------Attaching RT to the second public subent ---------------------------------------
resource "aws_route_table_association" "b" {
  subnet_id      = data.aws_subnet.selectedSubnet2.id
  route_table_id = aws_route_table.PublicRouteTable.id
}


#--------------------------------Creating Private Route table for Private subnets ---------------------------------
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.TerraformVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }
}


#-------------------------------Getting Information about the Private subnets  ---------------------------------------------------
data "aws_subnet" "selectedSubnet3" {
  filter {
    name   = "tag:Name"
    values = ["Privatesubnet1"]
  }
  depends_on = [ aws_subnet.Privateubnet1 ]
}

data "aws_subnet" "selectedSubnet4" {
  filter {
    name   = "tag:Name"
    values = ["Privatesubnet2"]
  }
  depends_on = [ aws_subnet.Privateubnet2 ]
}

data "aws_subnet" "selectedSubnet5" {
  filter {
    name   = "tag:Name"
    values = ["Privatesubnet3"]
  }
  depends_on = [ aws_subnet.Privateubnet3 ]
}


data "aws_subnet" "selectedSubnet6" {
  filter {
    name   = "tag:Name"
    values = ["Privatesubnet4"]
  }
  depends_on = [ aws_subnet.Privateubnet4 ]
}


#---------------------------Attaching the RT to Private subnets -----------------------------------------------
resource "aws_route_table_association" "c" {
  subnet_id      = data.aws_subnet.selectedSubnet3.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}


resource "aws_route_table_association" "d" {
  subnet_id      = data.aws_subnet.selectedSubnet4.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_route_table_association" "e" {
  subnet_id      = data.aws_subnet.selectedSubnet5.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_route_table_association" "f" {
  subnet_id      = data.aws_subnet.selectedSubnet6.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}


