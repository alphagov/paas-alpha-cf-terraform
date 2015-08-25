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

resource "aws_security_group" "bosh-ports" {
  name = "${var.env}-cf-microbosh"
  description = "SSH and Bosh ports from trusted external sources"
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
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port = 4222
    to_port   = 4222
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port = 6868
    to_port   = 6868
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port = 25250
    to_port   = 25250
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port = 25555
    to_port   = 25555
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port = 25777
    to_port   = 25777
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  tags {
    Name = "${var.env}-cf-microbosh"
  }

}
