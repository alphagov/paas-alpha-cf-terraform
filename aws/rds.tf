resource "aws_db_subnet_group" "cf_rds_subnet" {
    name = "${var.env}-cf-rds-subnet"
    description = "Subnet group for RDS"
    subnet_ids = [
      "${aws_subnet.private.id}",
      "${aws_subnet.public.id}"
    ]
}

resource "aws_db_instance" "uaadb" {
    identifier = "${var.env}-uaadb-rds"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6.23"
    instance_class = "db.t1.micro"
    name = "uaadb"
    username = "uaadb"
    password = "uaadbpassword"
    db_subnet_group_name = "${var.env}-cf-rds-subnet"
    parameter_group_name = "default.mysql5.6"
    vpc_security_group_ids = ["${aws_security_group.rds.id}"]
}

resource "aws_db_instance" "ccdb" {
    identifier = "${var.env}-ccdb-rds"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6.23"
    instance_class = "db.t1.micro"
    name = "ccdb"
    username = "ccdb"
    password = "ccdbpassword"
    db_subnet_group_name = "${var.env}-cf-rds-subnet"
    parameter_group_name = "default.mysql5.6"
    vpc_security_group_ids = ["${aws_security_group.rds.id}"]
}

resource "aws_security_group" "rds" {
  name = "${var.env}-rds"
  description = "RDS security group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      "${aws_security_group.director.id}",
      "${aws_security_group.bosh_vm.id}"
    ]
  }

  tags {
    Name = "${var.env}-rds"
  }
}
