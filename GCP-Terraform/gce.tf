# compute instance
resource "google_compute_instance" "default" {
  name         = "temp-vm"
  machine_type = "e2-standard-4"
  zone         = "asia-northeast3-a"
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "rocky-linux-9-optimized-gcp-v20220920"
    }
  }

  metadata_startup_script = templatefile("userdata.tftpl", {
    db_endpoint = "${google_sql_database_instance.petclinic.private_ip_address}"
  })

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id

    access_config {

    }
  }
  depends_on = [
    google_compute_instance.default,
    google_sql_database.petclinic,
    google_sql_user.petclinic,
  ]

}

resource "time_sleep" "wait_12_minutes" {
  create_duration = "12m"

  depends_on = [google_compute_instance.default]
}


resource "google_compute_global_address" "private_ip_address" {

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}


resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}