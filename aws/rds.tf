resource "aws_db_subnet_group" "cf_rds_subnet" {
    name = "${var.env}-cf-rds-subnet"
    description = "Subnet group for RDS"
    subnet_ids = [
      "${aws_subnet.infra.*.id}"
    ]
}

resource "aws_db_instance" "uaadb" {
    identifier = "${var.env}-uaadb-rds"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6.23"
    instance_class = "db.t2.micro"
    name = "uaadb"
    username = "${var.uaadb_username}"
    password = "${var.uaadb_password}"
    db_subnet_group_name = "${aws_db_subnet_group.cf_rds_subnet.name}"
    parameter_group_name = "default.mysql5.6"
    vpc_security_group_ids = ["${aws_security_group.rds.id}"]
}

resource "aws_db_instance" "ccdb" {
    identifier = "${var.env}-ccdb-rds"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.6.23"
    instance_class = "db.t2.micro"
    name = "ccdb"
    username = "${var.ccdb_username}"
    password = "${var.ccdb_password}"
    db_subnet_group_name = "${aws_db_subnet_group.cf_rds_subnet.name}"
    parameter_group_name = "default.mysql5.6"
    vpc_security_group_ids = ["${aws_security_group.rds.id}"]
}
