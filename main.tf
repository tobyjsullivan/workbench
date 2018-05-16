terraform {
  backend "s3" {
    bucket = "terraform-states.tobyjsullivan.com"
    key    = "states/workbench/terraform.tfstate"
    region = "us-east-1"
  }
}

variable "public_key" {}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_security_group" "ssh_in" {
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
}

resource "aws_key_pair" "workbench" {
  key_name_prefix = "workbench"
  public_key = "${var.public_key}"
}

resource "aws_instance" "workbench" {
  ami = "ami-d38a4ab1"
  instance_type = "t2.micro"

  security_groups = ["${aws_security_group.ssh_in.name}"]
  key_name = "${aws_key_pair.workbench.key_name}"
}

output "ip_address" {
  value = "${aws_instance.workbench.public_ip}"
}

