resource "aws_eip" "bosh" {
  vpc = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "internet" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.bastion.id}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.private_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  depends_on = ["aws_instance.bastion"]
  tags {
    Name = "${var.env}-cf-private-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.internet.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.public_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "${var.env}-cf-public-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
