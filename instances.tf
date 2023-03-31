#Get linux AMI ID using ssm parameter endpoint in eu-central-1
data "aws_ssm_parameter" "lnuxAmi" {
  provider = aws.master-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get linux AMI ID using ssm parameter endpoint in eu-west-2
data "aws_ssm_parameter" "lnuxAmiLondon" {
  provider = aws.worker-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
