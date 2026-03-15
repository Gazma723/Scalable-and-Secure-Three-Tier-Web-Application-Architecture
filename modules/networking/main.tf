############################################
# VPC
############################################

resource "aws_vpc" "nexsecure_vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nexsecure-vpc"
  }
}

############################################
# AVAILABILITY ZONES
############################################

data "aws_availability_zones" "available" {}

############################################
# INTERNET GATEWAY
############################################

resource "aws_internet_gateway" "nexsecure_igw" {

  vpc_id = aws_vpc.nexsecure_vpc.id

  tags = {
    Name = "nexsecure-igw"
  }
}

############################################
# PUBLIC SUBNETS
############################################

resource "aws_subnet" "public_subnets" {

  count = var.public_sn_count

  vpc_id                  = aws_vpc.nexsecure_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "nexsecure-public-${count.index + 1}"
  }
}

############################################
# PUBLIC ROUTE TABLE
############################################

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.nexsecure_vpc.id

  tags = {
    Name = "nexsecure-public-rt"
  }
}

resource "aws_route" "public_internet_access" {

  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nexsecure_igw.id
}

resource "aws_route_table_association" "public_assoc" {

  count = var.public_sn_count

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# NAT GATEWAY
############################################

resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {
    Name = "nexsecure-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "nexsecure-nat"
  }

  depends_on = [aws_internet_gateway.nexsecure_igw]
}

############################################
# PRIVATE SUBNETS
############################################

resource "aws_subnet" "private_subnets" {

  count = var.private_sn_count

  vpc_id            = aws_vpc.nexsecure_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "nexsecure-private-${count.index + 1}"
  }
}

############################################
# PRIVATE ROUTE TABLE
############################################

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.nexsecure_vpc.id

  tags = {
    Name = "nexsecure-private-rt"
  }
}

resource "aws_route" "private_nat_route" {

  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {

  count = var.private_sn_count

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

############################################
# DATABASE SUBNETS
############################################

resource "aws_subnet" "db_subnets" {

  count = var.private_sn_count

  vpc_id            = aws_vpc.nexsecure_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "nexsecure-db-${count.index + 1}"
  }
}

############################################
# DATABASE SUBNET GROUP
############################################

resource "aws_db_subnet_group" "db_subnet_group" {

  count = var.db_subnet_group ? 1 : 0

  name       = "nexsecure-db-subnet-group"
  subnet_ids = aws_subnet.db_subnets[*].id

  tags = {
    Name = "nexsecure-db-subnet-group"
  }
}

############################################
# SECURITY GROUPS
############################################

### BASTION

resource "aws_security_group" "bastion_sg" {

  name        = "nexsecure-bastion-sg"
  description = "SSH access from admin IP"
  vpc_id      = aws_vpc.nexsecure_vpc.id

  ingress {

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### LOAD BALANCER

resource "aws_security_group" "lb_sg" {

  name        = "nexsecure-alb-sg"
  description = "Allow HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.nexsecure_vpc.id

  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### FRONTEND APP

resource "aws_security_group" "frontend_sg" {

  name   = "nexsecure-frontend-sg"
  vpc_id = aws_vpc.nexsecure_vpc.id

  ingress {

    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {

    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### BACKEND APP

resource "aws_security_group" "backend_sg" {

  name   = "nexsecure-backend-sg"
  vpc_id = aws_vpc.nexsecure_vpc.id

  ingress {

    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {

    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### RDS

resource "aws_security_group" "rds_sg" {

  name   = "nexsecure-rds-sg"
  vpc_id = aws_vpc.nexsecure_vpc.id

  ingress {

    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
