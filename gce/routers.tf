resource "google_compute_target_pool" "router" {
  name = "${var.env}-cf-router-lb"
}

resource "google_compute_address" "router" {
  name = "${var.env}-cf-router-lb"
}

resource "google_compute_forwarding_rule" "router_http" {
  name = "${var.env}-cf-router-lb-http"
  ip_address = "${google_compute_address.router.address}"
  target = "${google_compute_target_pool.router.self_link}"
  port_range = 80
}

resource "google_compute_forwarding_rule" "router_https" {
  name = "${var.env}-cf-router-lb-https"
  ip_address = "${google_compute_address.router.address}"
  target = "${google_compute_target_pool.router.self_link}"
  port_range = 443
}
