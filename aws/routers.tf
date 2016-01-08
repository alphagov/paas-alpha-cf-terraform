resource "aws_elb" "router" {
  name = "${var.env}-cf-router-elb"
  subnets = ["${aws_subnet.infra.*.id}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.web.id}",
  ]

  health_check {
    target = "TCP:22"
    interval = "${var.health_check_interval}"
    timeout = "${var.health_check_timeout}"
    healthy_threshold = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  listener {
    instance_port = 443
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
  }
  listener {
    instance_port = 2222
    instance_protocol = "tcp"
    lb_port = 2222
    lb_protocol = "tcp"
  }
}

