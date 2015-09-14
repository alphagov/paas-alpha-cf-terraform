resource "aws_s3_bucket" "buildpack-s3" {
    bucket = "${var.env}-cf-buildpacks"
    acl = "private"
}

resource "aws_s3_bucket" "droplets-s3" {
    bucket = "${var.env}-cf-droplets"
    acl = "private"
}

resource "aws_s3_bucket" "packages-s3" {
    bucket = "${var.env}-cf-packages"
    acl = "private"
}

resource "aws_s3_bucket" "resources-s3" {
    bucket = "${var.env}-cf-resources"
    acl = "private"
}
