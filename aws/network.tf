resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "bastion" {
  count             = 1
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.public_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "${var.env}-bastion-subnet-${count.index}"
  }
}

resource "aws_route_table" "internet" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "bastion" {
  count = 1
  subnet_id = "${element(aws_subnet.bastion.*.id, count.index)}"
  route_table_id = "${aws_route_table.internet.id}"
}

resource "aws_subnet" "cf_core" {
  count             = 1
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.cf_cidr, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "${var.env}-cf_core-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "cf_core" {
  count = 1
  subnet_id = "${element(aws_subnet.cf_core.*.id, count.index)}"
  route_table_id = "${aws_route_table.internet.id}"
}
