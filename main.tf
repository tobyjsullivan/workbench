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

data "aws_region" "current" {}

variable "aws_availability_zones" {
  type = "map"
  default = {
    "0" = "ap-southeast-2a"
    "1" = "ap-southeast-2b"
  }
}

variable "vpc_cidr_block" {
  default = "10.5.0.0/16"
}

variable "main_subnet_cidr_blocks" {
  type = "map"

  default = {
    "0" = "10.5.0.0/24"
    "1" = "10.5.1.0/24"
  }
}

variable "ubuntu_amis" {
  type = "map"

  default = {
    "us-east-1" = "ami-0ac019f4fcb7cb7e6"
    "ap-southeast-2" = "ami-d38a4ab1"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "main_az1" {
  cidr_block = "${lookup(var.main_subnet_cidr_blocks, "0")}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${data.aws_region.current.name}a"
}


resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "vpc" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "main_az1" {
  route_table_id = "${aws_route_table.vpc.id}"
  subnet_id = "${aws_subnet.main_az1.id}"
}

resource "aws_security_group" "ssh_in" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}

resource "aws_security_group" "all_out" {
  vpc_id = "${aws_vpc.main.id}"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_key_pair" "workbench" {
  key_name_prefix = "workbench"
  public_key      = "${var.public_key}"
}

resource "aws_instance" "workbench" {
  ami           = "${lookup(var.ubuntu_amis, data.aws_region.current.name)}"
  instance_type = "t2.micro"

  depends_on = ["aws_internet_gateway.gw"]
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main_az1.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh_in.id}",
    "${aws_security_group.all_out.id}",
  ]

  key_name = "${aws_key_pair.workbench.key_name}"
}

output "ip_address" {
  value = "${aws_instance.workbench.public_ip}"
}
