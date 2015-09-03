output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "bosh_ip" {
       value = "${aws_eip.bosh.public_ip}"
}
