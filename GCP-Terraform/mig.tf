resource "time_sleep" "wait_12_minutes" {
  depends_on = [google_compute_instance.default]

  create_duration = "12m"
}

resource "google_compute_snapshot" "web-snapshot" {
  name        = "web-snapshot"
  zone        = "asia-northeast3-a" #영역 지정
  source_disk = google_compute_instance.default.name #스냅샷 뜰 인스턴스  지정

  depends_on = [
    time_sleep.wait_12_minutes #인스턴스 생성 후 12분 뒤 스냅샷 생성
  ]
}

resource "google_compute_image" "web-image" {
  name            = "web-image"
  source_snapshot = google_compute_snapshot.web-snapshot.name #이미지 뜰  스냅샷 지정
  depends_on = [
    google_compute_snapshot.web-snapshot #스냅샷이 생성된 후 이미지 만들어라
  ]
}

resource "google_compute_instance_template" "tf-template" {
  name                    = "web-template"
  machine_type            = "e2-micro"  # 머신 타입
  tags                    = ["web"] #이 템플릿을 사용해 만들어진 인스턴스 에 태깅
  metadata_startup_script = "nohup java -jar ~/petclinic/target/*.jar --spring.profiles.active=mysql &" #시작 스크립트 지정

  disk {
    source_image = google_compute_image.web-image.id #템플릿 생성에 이용할 이미지 지정
  }

  network_interface {
    network    = google_compute_network.vpc_network.id #vpc 선택
    subnetwork = google_compute_subnetwork.default.id # subnet 선택
  }

  depends_on = [google_compute_image.web-image] # 이미지 생성 후 템플릿 만들어라
}

resource "google_compute_region_instance_group_manager" "web-mig" {
  name = "web-mig" #web_mig의 리소스 이름

  base_instance_name        = "web-mig" #생성되는 인스턴스들에 붙을 이름
  region                    = "asia-northeast3"  #인스턴스 그룹 생성 될 리전 선택
  distribution_policy_zones = ["asia-northeast3-a", "asia-northeast3-b"] #영역 선택

  version {
    instance_template = google_compute_instance_template.tf-template.id #mig 생성시 사용할 템플릿 지정
  }

  named_port {
    name = "tomcat"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web-mig-autohealing.id
    initial_delay_sec = 300
  }

  depends_on = [google_compute_health_check.web-mig-autohealing, google_compute_instance_template.tf-template] #템플릿 생성 후 만들어라
}

resource "google_compute_health_check" "web-mig-autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/"
    port         = "8080"
  }
}

resource "google_compute_region_autoscaler" "web-mig-as-policy" {
  name   = "web-mig-autoscaler"
  region = "asia-northeast3"
  target = google_compute_region_instance_group_manager.web-mig.id

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
  depends_on = [google_compute_region_instance_group_manager.web-mig]
}