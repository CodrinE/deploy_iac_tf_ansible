variable "profile" {
  type    = string
  default = "default"
}
variable "master-region" {
  type    = string
  default = "eu-central-1"
}

variable "worker-region" {
  type    = string
  default = "eu-west-2"
}

variable "ingress_rules_lb" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    description = "Allow https from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }, {
    description = "Allow http from anywhere for redirection"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
  validation {
    condition = alltrue([
      for r in var.ingress_rules_lb : r.protocol != "-1"
    ])
    error_message = "Protocol can't be all"
  }
}

variable "ingress_rules_jenkins" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    description = "Allow ssh from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }, {
    description = "Allow anyone on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = null
    }, {
    description = "Allow traffic from eu-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }]
}

variable "ingress_rules_worker" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }, {
    description = "Allow traffic from eu-central-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }]
}

variable "key_name" {
  type    = string
  default = "aws_key_jenkins"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "workers_count" {
  type    = number
  default = 1
}

variable "webserver_port" {
  type    = number
  default = 8080
}