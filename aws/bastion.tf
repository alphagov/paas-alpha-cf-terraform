resource "aws_instance" "bastion" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.bastion.0.id}"
  private_ip = "10.0.0.4"
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

  provisioner "remote-exec" {
        inline = ["cat << EOF > /home/ubuntu/manifest_aws.yml",
         "${template_file.manifest.rendered}",
         "EOF"]
  }

  provisioner "remote-exec" {
        inline = ["cat << EOF > /home/ubuntu/cf_manifest_aws.yml",
         "${template_file.cf_manifest.rendered}",
         "EOF"]
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer"
          destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
          source = "${path.module}/ssh/insecure-deployer.pub"
          destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
      source = "${path.module}/provision.sh"
      destination = "/home/ubuntu/provision.sh"
  }
}
