resource "google_compute_target_pool" "graphite" {
  name = "${var.env}-graphite-lb"
}

resource "google_compute_address" "graphite" {
  name = "${var.env}-graphite-lb"
}

resource "google_compute_forwarding_rule" "graphite_http" {
  name = "${var.env}-graphite-lb-http"
  ip_address = "${google_compute_address.graphite.address}"
  target = "${google_compute_target_pool.graphite.self_link}"
  port_range = 80
}

resource "google_compute_forwarding_rule" "graphite_3000" {
  name = "${var.env}-graphite-lb-3000"
  ip_address = "${google_compute_address.graphite.address}"
  target = "${google_compute_target_pool.graphite.self_link}"
  port_range = 3000
}
