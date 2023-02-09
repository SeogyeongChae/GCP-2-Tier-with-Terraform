resource "google_sql_database_instance" "sql" {
  name                = "petclinic"
  database_version    = "MYSQL_5_7"
  root_password       = "petclinic"
  deletion_protection = false

  settings {
    tier              = "db-custom-2-3840"
    availability_type = "ZONAL"
    disk_size         = 10
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_user" "db_users" {
  name     = "petclinic"
  instance = google_sql_database_instance.sql.name
  password = "petclinic"
  # host =
}

resource "google_sql_database" "tf_db_database" {
  name     = "petclinic"
  instance = google_sql_database_instance.sql.name
}