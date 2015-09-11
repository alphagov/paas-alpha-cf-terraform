resource "aws_instance" "bastion" {
  ami = "${lookup(var.ubuntu_amis, var.region)}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public.0.id}"
  private_ip = "10.0.0.4"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name = "${var.key_pair_name}"
  source_dest_check = false

  root_block_device = {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.env}-bastion"
  }
  connection {
    user = "ubuntu"
    key_file = "ssh/insecure-deployer"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer"
          destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer.pub"
          destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "remote-exec" {
    script = "../setup-nat-routing.sh"
  }

}

resource "aws_security_group" "nat" {
  name = "${var.env}-nat-cf"
  description = "Security group for nat instances that allows SSH from whitelisted IPs from internet"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}","${var.jenkins_elastic}"]
  }

  tags {
    Name = "${var.env}-cf-nat"
  }
}

resource "aws_security_group" "cf_route" {
  name = "${var.env}-nat-route-cf"
  description = "Security group for nat instances that allows routing VPC traffic to internet"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      "${aws_security_group.default.id}"
    ]
  }

  tags {
    Name = "${var.env}-cf-nat-route"
  }
}
