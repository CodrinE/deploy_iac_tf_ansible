#Create VPC in eu-central-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.master-region
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

#Create VPC in eu-west-2
resource "aws_vpc" "vpc_master_london" {
  provider             = aws.worker-region
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

#Create IGW in eu-central-1
resource "aws_internet_gateway" "igw" {
  provider = aws.master-region
  vpc_id   = aws_vpc.vpc_master.id
}
#Create IGW in eu-west-2
resource "aws_internet_gateway" "igw-london" {
  provider = aws.worker-region
  vpc_id   = aws_vpc.vpc_master_london.id
}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.master-region
  state    = "available"
}

#Create subnet # 1 in eu-central-1
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.vpc_master.id
  provider          = aws.master-region
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  cidr_block        = "10.0.1.0/24"
}

#Create subnet # 2 in eu-central-1
resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.vpc_master.id
  provider          = aws.master-region
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  cidr_block        = "10.0.2.0/24"
}

#Create subnet in eu-west-2
resource "aws_subnet" "subnet_1_london" {
  vpc_id     = aws_vpc.vpc_master_london.id
  provider   = aws.worker-region
  cidr_block = "192.168.1.0/24"
}

#Initiate Peering connection request from eu-central-1
resource "aws_vpc_peering_connection" "eucentral1-euwest2" {
  provider    = aws.master-region
  peer_vpc_id = aws_vpc.vpc_master_london.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.worker-region
}

#accept VPC peering request in eu-west-2 from eu-central-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  vpc_peering_connection_id = aws_vpc_peering_connection.eucentral1-euwest2.id
  provider                  = aws.worker-region
  auto_accept               = true
}

#Creatr route table in eu-central-1
resource "aws_route_table" "internet_route" {
  vpc_id   = aws_vpc.vpc_master.id
  provider = aws.master-region
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.eucentral1-euwest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

#Overrite default route table of Master VPC with our entries
resource "aws_main_route_table_association" "set_master_default_rt_association" {
  route_table_id = aws_route_table.internet_route.id
  vpc_id         = aws_vpc.vpc_master.id
  provider       = aws.master-region
}

#Create rout table in eu-west-2
resource "aws_route_table" "internet_route_london" {
  vpc_id   = aws_vpc.vpc_master_london.id
  provider = aws.worker-region
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-london.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.eucentral1-euwest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

#Overrite default route table of Worker VPC with our entries
resource "aws_main_route_table_association" "set_worker_default_rt_association" {
  route_table_id = aws_route_table.internet_route_london.id
  vpc_id         = aws_vpc.vpc_master_london.id
  provider       = aws.worker-region
}