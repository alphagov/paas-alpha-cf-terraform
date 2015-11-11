resource "aws_security_group" "bastion" {
  name = "${var.env}-bastion"
  description = "Security group for bastion that allows NAT traffic and SSH connections from the office and jenkins"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}", "${var.jenkins_elastic}"]
  }

  tags {
    Name = "${var.env}-bastion"
  }
}

resource "aws_security_group" "director" {
  name = "${var.env}-director"
  description = "Microbosh security group"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
    ]
  }

  ingress {
    from_port = 6868
    to_port   = 6868
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
    ]
  }

  ingress {
    from_port = 4222
    to_port   = 4222
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
      "${aws_security_group.bosh_vm.id}",
    ]
  }

  ingress {
    from_port = 25250
    to_port   = 25250
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
      "${aws_security_group.bosh_vm.id}",
    ]
  }

  ingress {
    from_port = 25555
    to_port   = 25555
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
    ]
  }

  ingress {
    from_port = 25555
    to_port   = 25555
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.public_ip}/32"]
  }

  ingress {
    from_port = 25777
    to_port   = 25777
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
      "${aws_security_group.bosh_vm.id}",
    ]
  }

  tags {
    Name = "${var.env}-director"
  }
}

resource "aws_security_group" "bosh_vm" {
  name = "${var.env}-bosh-vm"
  description = "Security group for VMs managed by Bosh"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags {
    Name = "${var.env}-bosh-vm"
  }
}

resource "aws_security_group" "web" {
  name = "${var.env}-web-cf"
  description = "Security group for web that allows web traffic from the office and jenkins"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.office_cidrs)}",
      "${aws_instance.bastion.public_ip}/32",
      "${var.jenkins_elastic}"
    ]
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.office_cidrs)}",
      "${aws_instance.bastion.public_ip}/32",
      "${var.jenkins_elastic}"
    ]
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  ingress {
    from_port = 4443
    to_port   = 4443
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.office_cidrs)}",
      "${aws_instance.bastion.public_ip}/32",
      "${var.jenkins_elastic}"
    ]
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  tags {
    Name = "${var.env}-cf-web"
  }
}

resource "aws_security_group" "graphite" {
  name = "${var.env}-graphite"
  description = "Security group for graphite that allows web traffic from the office and jenkins"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.office_cidrs)}",
      "${aws_instance.bastion.public_ip}/32",
      "${var.jenkins_elastic}"
    ]
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", var.office_cidrs)}",
      "${aws_instance.bastion.public_ip}/32",
      "${var.jenkins_elastic}"
    ]
    security_groups = [
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  tags {
    Name = "${var.env}-graphite"
  }
}
