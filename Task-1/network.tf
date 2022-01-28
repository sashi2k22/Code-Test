# VPC Resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "test1-vpc"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "test1-internet-gateway"
  }
}


# Public Subnet
resource "aws_subnet" "public_subnet" {
  for_each = var.az_public_subnet

  vpc_id = aws_vpc.main.id

  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "test1-public-subnet-${each.key}"
  }
}


# Private Subnet
resource "aws_subnet" "private_subnet" {
  for_each = var.az_private_subnet

  vpc_id = aws_vpc.main.id

  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "test1-private-subnet-${each.key}"
  }
}


resource "aws_subnet" "database_subnet" {
  for_each = var.az_database_subnet

  vpc_id = aws_vpc.main.id

  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "test1-database-subnet-${each.key}"
  }
}


# Route Table 
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "test1-public-subnet-route-table"
  }
}

# Public subnet route table association
resource "aws_route_table_association" "public_subnet_route_table_association" {
  for_each = var.az_public_subnet

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_subnet_route_table.id
}