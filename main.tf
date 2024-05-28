resource "aws_instance" "jenkins-server" {
  ami = data.aws_ami.amazon-ami.id
  instance_type = t2.micro

  tags = {
    "Name" = "Jenkins-server"
  }
  user_data = file("./install-jenkins.sh")
  key_name = aws_key_pair.pub-key.key_name
  depends_on = [ tls_private_key.pvt-key,local_file.access-key,aws_key_pair.pub-key ]
  vpc_security_group_ids = [ aws_security_group.jenkins_sg.id ]
}

data "aws_ami" "amazon-ami" {
  owners = [ "amazon" ]
  most_recent = true
  
  filter {
    name = "virtualization"
    values = [ "hvm" ]
  }
  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name = "architecture"
    values = "x86_64"

  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins server"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_key_pair" "pub-key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.pvt-key.public_key_openssh
}

resource "tls_private_key" "pvt-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "access-key" {
  content  = tls_private_key.pvt-key.private_key_openssh
  filename = "jenkins.pem"
  file_permission = "400"
}
