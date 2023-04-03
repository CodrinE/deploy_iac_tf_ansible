#Create SG for LB. only TCP/80, TCP/443 and outbound access
resource "aws_security_group" "lb_sg" {
  provider = aws.master-region
  name     = "lb_sg"
  vpc_id   = aws_vpc.vpc_master.id
  dynamic "ingress" {
    for_each = var.ingress_rules_lb
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      protocol    = ingress.value["protocol"]
    }
  }
  egress {
    from_port        = 0
    protocol         = "-1"
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "lb_sg"
  }
}

#Create SG for allowing TCp/8080 from * and TCP/22 from your ip in eu-central-1
resource "aws_security_group" "jenkins_sg" {
  provider    = aws.master-region
  name        = "jenkins-sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  dynamic "ingress" {
    for_each = var.ingress_rules_jenkins
    content {
      description     = ingress.value["description"]
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      security_groups = ingress.value["to_port"] == 80 ? [aws_security_group.lb_sg.id] : null
      cidr_blocks     = ingress.value["cidr_blocks"]
      protocol        = ingress.value["protocol"]
    }
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    NAME = "jenkins_sg"
  }
}
#create SG for allowing TCP/22 from your IP in eu-west-2
resource "aws_security_group" "jenkins_sg_london" {
  provider    = aws.worker-region
  name        = "jenkins-sg-worker"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_master_london.id
  dynamic "ingress" {
    for_each = var.ingress_rules_worker
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      protocol    = ingress.value["protocol"]
    }
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}