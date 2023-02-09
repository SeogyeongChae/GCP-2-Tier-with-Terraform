# Compute network
resource "google_compute_network" "default" {
  name                    = "petclinic-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Compute subnet
resource "google_compute_subnetwork" "default" {
  name          = "petclinic-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.default.id
}