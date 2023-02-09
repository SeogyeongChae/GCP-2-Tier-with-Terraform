# Allow-8080-ig
resource "google_compute_firewall" "allow-8080-ig" {
  name      = "allow-8080-ig"
  network   = google_compute_network.default.name
  direction = "INGRESS"
  priority  = 300

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
}
  #   source_tags = [ "value" ]
  #   source_ranges =  ["35.191.0.0/16", "130.211.0.0/22"]

# Allow-22-ig
resource "google_compute_firewall" "allow-22-ig" {
  name      = "allow-22-ig"
  network   = google_compute_network.default.name
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
}

  #   source_tags = [ "value" ]
  #   source_ranges = [ "35.235.240.0/20" ]

# Allow-all-eg
resource "google_compute_firewall" "allow-all-eg" {
  name      = "allow-all-eg"
  network   = google_compute_network.default.name
  direction = "EGRESS"
  priority  = 65535

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}
### egress에 대해서 모튼 포트와 IP 영역을 설정

# deny-all-ig
resource "google_compute_firewall" "deny-all-ig" {
  name      = "deny-all-ig"
  network   = google_compute_network.default.name
  direction = "INGRESS"
  priority  = 65535

  deny {
    protocol = "all"

  }
  source_ranges = ["0.0.0.0/0"]
}
### ingress에 대해 모든 포트와 IP 영역을 거부하는 설정