# LB에 연결해줄 공인 IP 예약
resource "google_compute_global_address" "lb_ip" {
  name = "lb-static-ip"
  // INTERNAL, EXTERNAL 두 종류가 있음
  # address_type = "EXTERNAL"  // Default : EXTERNAL
}

# backend service
resource "google_compute_backend_service" "backend" {
  name                  = "tf-backend-service"
  protocol              = "HTTP"

  load_balancing_scheme = "EXTERNAL"
        # EXTERNAL LB의 경우 필수 설정
  port_name             = "tomcat" # MIG 구성의 포트 이름과 동일하게 작성

        # 백엔드의 응답 대기 시간 | default : 30
  timeout_sec           = 10

  # CDN 사용 설정
  enable_cdn    = false
  health_checks = [google_compute_health_check.lb_check.id]
  backend {
                # 백엔드 그룹 지정 -> MIG 그룹
    group           = google_compute_region_instance_group_manager.web-mig.instance_group

                # CONNECTION: 백엔드에서 처리할 수 있는 동시 연결 수를 기 준으로 부하가 분산되는 방식을 결정
                # RATE: 초당 최대 대상 요청(쿼리) 수(RPS, QPS)입니다. 모든 최대 백엔드가 용량에 도달하거나 용량을 초과할 경우 대상 최대 RPS/QPS를 초과할 수 있음
                # UTILIZATION: 인스턴스 그룹의 인스턴스 사용률에 따라 부하가 분산되는 방식을 결정
    balancing_mode  = "UTILIZATION"
                # 밸런싱 모드에 따라 비율을 설정 [0.0 ~ 1.0]
    capacity_scaler = 1.0
  }
}

# health check
resource "google_compute_health_check" "lb_check" {
  name = "tf-http-hc"

  # check_interval_sec = 1

  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

# Health Check 실시 주기, Default = 5
# check_interval_sec = 5

# USE_FIXED_PORT: 포트의 포트 번호는 상태 확인에 사용
# USE_NAMED_PORT: portName은 상태 확인에 사용
# USE_SERVING_PORT: NetworkEndpointGroup의 경우 각 네트워크 끝점에 대해 지정된 포트가 상태 확인에 사용
#                   다른 백엔드의 경우 백엔드 서비스에 지정된 포트 또는 명명된 포트가 상태 확인에 사용
# 지정하지 않으면 HTTP 상태 확인은 port 및 portName 필드에 지정된 동작을 따름
http_health_check {
  port_specification = "USE_SERVING_PORT"
}

resource "google_compute_url_map" "default" {
  name            = "tf-url-map"
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_url_map" "https-redirect" {
  name            = "url-map"
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# UrlMaps는 수신 URL의 호스트 및 경로에 대해 정의한 규칙을 기반으로 요청을 백엔드 서비스로 라우팅하는 데 사용
# 현재 호스트 & 경로에 대한 규칙이 없기 때문에 생략
# 요청 헤더, 호스트, 경로 관리 등을 설정 가능
resource "google_compute_url_map" "map" {
  name            = "tf-url-map"
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_target_http_proxy" "default" {
  name             = "http-proxy"
  url_map          = google_compute_url_map.https-redirect.id
}



# HTTP 요청을 url map 으로 연결해주기 위한 설정
resource "google_compute_target_http_proxy" "proxy" {
  name    = "lb-http-proxy"
  url_map = google_compute_url_map.map.id
}