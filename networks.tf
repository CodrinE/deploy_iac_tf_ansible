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