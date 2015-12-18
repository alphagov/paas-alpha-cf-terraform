resource "aws_subnet" "cf" {
  count             = 2
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.cf_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = false
  depends_on = ["aws_instance.bastion"]
  tags {
    Name = "${var.env}-cf-subnet-${count.index}"
  }
}

resource "aws_route_table" "cf" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.bastion.id}"
  }
}

resource "aws_route_table_association" "cf" {
  count = 2
  subnet_id = "${element(aws_subnet.cf.*.id, count.index)}"
  route_table_id = "${aws_route_table.cf.id}"
}
