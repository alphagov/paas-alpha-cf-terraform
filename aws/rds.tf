resource "aws_db_instance" "uaadb" {
    identifier = "${var.env}-uaadb-rds"
    allocated_storage = 10
    engine = "postgres"
    engine_version = "9.4.1"
    instance_class = "db.t1.micro"
    name = "uaadb"
    username = "uaadb"
    password = "uaadbpassword"
}

resource "aws_db_instance" "ccdb" {
    identifier = "${var.env}-ccdb-rds"
    allocated_storage = 10
    engine = "postgres"
    engine_version = "9.4.1"
    instance_class = "db.t1.micro"
    name = "ccdb"
    username = "ccdb"
    password = "ccdbpassword"
}
