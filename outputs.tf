output "vpc-id-eu-central-1" {
  value = aws_vpc.vpc_master.id
}

output "vpc-id-eu-west-2" {
  value = aws_vpc.vpc_master_london.id
}

output "peering-connection-id" {
  value = aws_vpc_peering_connection.eucentral1-euwest2.id
}