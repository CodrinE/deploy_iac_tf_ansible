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
#Save pem key locally
resource "local_file" "devkey" {
  filename = "${path.module}/${var.key_name}.pem"
  content  = tls_private_key.dev_priv_key.private_key_pem
}
#Create a PEM private key
resource "tls_private_key" "dev_priv_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
#Register key to AWS to allow logging-in to EC2 instances in eu-central-1
resource "aws_key_pair" "master_key" {
  public_key = tls_private_key.dev_priv_key.public_key_openssh
  key_name   = var.key_name
  provider   = aws.master-region
}

#Register key to AWS to allow logging-in to EC2 instances in eu-west-2
resource "aws_key_pair" "worker_key" {
  public_key = tls_private_key.dev_priv_key.public_key_openssh
  key_name   = var.key_name
  provider   = aws.worker-region
}