resource "aws_security_group" "default" {
  name = "${var.env}-default-cf"
  description = "Default security group which allows SSH access and outbound traffic"
  vpc_id = "${aws_vpc.default.id}"

  # Allow inbound SSH access
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [
      "${aws_security_group.nat.id}"
    ]
  }

  # Allow outbound traffic via NAT box
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.env}-cf-default"
  }
}

resource "aws_security_group" "web" {
  name = "${var.env}-web-cf"
  description = "Security group for web that allows web traffic from internet"
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
    cidr_blocks = ["${split(",", var.office_cidrs)}","${var.jenkins_elastic}","${aws_instance.bastion.public_ip}/32"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}","${var.jenkins_elastic}","${aws_instance.bastion.public_ip}/32"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["${split(",", var.office_cidrs)}","${var.jenkins_elastic}","${aws_instance.bastion.public_ip}/32"]
  }

  tags {
    Name = "${var.env}-cf-web"
  }
}
