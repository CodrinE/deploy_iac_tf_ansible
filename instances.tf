#Get linux AMI ID using ssm parameter endpoint in eu-central-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.master-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get linux AMI ID using ssm parameter endpoint in eu-west-2
data "aws_ssm_parameter" "linuxAmiLondon" {
  provider = aws.worker-region
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}
#Save pem key locally
resource "local_file" "devkey" {
  filename = "${var.key_name}.pem"
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

#Create EC2 instance in eu-central-1
resource "aws_instance" "jenkins-master" {
  provider                    = aws.master-region
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.master_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = aws_subnet.subnet_1.id
  iam_instance_profile        = aws_iam_instance_profile.test_profile.name

  tags = {
    Name = "jenkins_master_tf"
  }
  depends_on = [aws_iam_role_policy.test_policy, aws_main_route_table_association.set_master_default_rt_association]

  provisioner "local-exec" {
    interpreter = ["/usr/bin/bash", "-c"]
    command     = <<EOF
ls -al  ./ansible_templates > test.txt
aws ec2 wait instance-status-ok --region ${var.master-region} --instance-ids ${self.id} \
&& ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ${path.module}/ansible_templates/install_jenkins.yaml
EOF
  }
}

resource "null_resource" "jenkins-worker" {
  count = var.workers_count
  triggers = {
    master_private_ip       = aws_instance.jenkins-master.private_ip
    private_key             = local_file.devkey.filename
    worker_public_ip        = aws_instance.jenkins-worker[count.index].public_ip
    worker_private_ip       = aws_instance.jenkins-worker[count.index].private_ip
    current_ec2_instance_id = element(aws_instance.jenkins-worker.*.id, count.index)
  }
  connection {
    private_key = file(self.triggers.private_key)
    type        = "ssh"
    user        = "ec2-user"
    host        = self.triggers.worker_public_ip
  }
  provisioner "local-exec" {
    when    = destroy
    command = "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${self.triggers.master_private_ip}:8080 -auth @/home/ec2-user/jenkins_auth delete-node ${self.triggers.worker_private_ip}"
  }
}

#Create EC2 instance in eu-west-2
resource "aws_instance" "jenkins-worker" {
  provider                    = aws.worker-region
  count                       = var.workers_count
  ami                         = data.aws_ssm_parameter.linuxAmiLondon.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.worker_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg_london.id]
  subnet_id                   = aws_subnet.subnet_1_london.id
  iam_instance_profile        = aws_iam_instance_profile.test_profile.name

  connection {
    private_key = file(local_file.devkey.filename)
    type        = "ssh"
    user        = "ec2-user"
    host        = self.private_ip
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/bash", "-c"]
    command     = <<EOF
aws ec2 wait instance-status-ok --region ${var.worker-region} --instance-ids ${self.id} \
&& ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} master_ip=${aws_instance.jenkins-master.private_ip}' ${path.module}/ansible_templates/install_worker.yaml
EOF
  }

  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set_worker_default_rt_association, aws_instance.jenkins-master]

}