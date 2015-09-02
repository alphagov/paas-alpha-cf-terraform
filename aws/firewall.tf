resource "aws_security_group" "bastion" {
  name = "${var.env}-bastion"
  description = "Security group for bastion that allows SSH traffic from the office"
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
    cidr_blocks = ["${split(",", var.office_cidrs)}"]
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
    from_port = 4222
    to_port   = 4222
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
      "${aws_security_group.bosh_vm.id}",
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
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}",
    ]
  }

  tags {
    Name = "${var.env}-bosh-vm"
  }
}

resource "aws_security_group" "nats" {
  name = "${var.env}-nats"
  description = "Security group for NATS"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags {
    Name = "${var.env}-nats"
  }
}
