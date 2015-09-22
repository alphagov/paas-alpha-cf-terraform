resource "aws_instance" "bastion" {
  ami = "${lookup(var.ubuntu_amis, var.region)}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.infra.0.id}"
  private_ip = "10.0.0.4"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name = "${var.key_pair_name}"
  source_dest_check = false

  root_block_device = {
    volume_type = "gp2"
    volume_size = 100
  }

  tags = {
    Name = "${var.env}-bastion"
  }
  connection {
    user = "ubuntu"
    key_file = "ssh/insecure-deployer"
  }

  provisioner "file" {
    source = "${path.module}/ssh/insecure-deployer"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
    source = "${path.module}/ssh/insecure-deployer.pub"
    destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "remote-exec" {
    inline = [
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa",
      "chmod 400 /home/ubuntu/.ssh/id_rsa"
    ]
  }
}
