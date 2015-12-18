resource "aws_elb" "graphite" {
  name = "${var.env}-graphite-elb"
  subnets = ["${aws_subnet.infra.*.id}"]
  idle_timeout = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  security_groups = [
    "${aws_security_group.graphite.id}",
  ]

  health_check {
    target = "TCP:80"
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
    instance_port = 3000
    instance_protocol = "http"
    lb_port = 3000
    lb_protocol = "http"
  }
}
