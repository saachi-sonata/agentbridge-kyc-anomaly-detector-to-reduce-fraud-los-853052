terraform {
  required_version = ">= 1.5"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }

  # Remote state in DigitalOcean Spaces (S3-compatible)
  backend "s3" {
    endpoints = {
      s3 = "https://${var.spaces_region}.digitaloceanspaces.com"
    }
    bucket                      = "agentbridge-tfstate"
    key                         = "deployments/kyc-anomaly-detector-to-reduce-fraud-los/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# ═══════════════════════════════════════════════════════════════
# PROJECT — Isolated boundary per deployment
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_project" "main" {
  name        = "ab-kyc-anomaly-detector-to-reduce-fraud-los"
  description = "AgentBridge: KYC Anomaly Detector to reduce fraud loss"
  purpose     = "Service or API"
  environment = var.environment == "production" ? "Production" : "Development"
  resources = compact([
    digitalocean_droplet.main.urn,
    var.enable_static_ip ? digitalocean_reserved_ip.main[0].urn : "",
    var.additional_storage_gb > 0 ? digitalocean_volume.data[0].urn : "",
    var.enable_spaces ? digitalocean_spaces_bucket.artifacts[0].urn : "",
    var.enable_load_balancer ? digitalocean_loadbalancer.main[0].urn : "",
  ])
}

# ═══════════════════════════════════════════════════════════════
# VPC — Dedicated network per deployment (10.x.y.0/24)
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_vpc" "main" {
  name        = "ab-kyc-anomaly-detector-to-reduce-fraud-los-vpc"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = "Isolated VPC for AgentBridge KYC Anomaly Detector to reduce fraud loss"
}

# ═══════════════════════════════════════════════════════════════
# SSH KEY
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_ssh_key" "deploy" {
  count      = var.ssh_public_key != "" ? 1 : 0
  name       = "ab-kyc-anomaly-detector-to-reduce-fraud-los-deploy"
  public_key = var.ssh_public_key
}

# ═══════════════════════════════════════════════════════════════
# FIREWALL — Least-privilege inbound rules
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_firewall" "main" {
  name = "ab-kyc-anomaly-detector-to-reduce-fraud-los-fw"

  droplet_ids = [digitalocean_droplet.main.id]

  # SSH — restricted to operator CIDRs only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }

  # HTTP — public (nginx reverse proxy)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS — public (TLS termination at nginx)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Application editor — restricted to operator CIDRs (NOT public)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5678"
    source_addresses = var.allowed_ssh_cidrs
  }

  # Prometheus metrics scrape — VPC internal only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9090"
    source_addresses = [var.vpc_cidr]
  }

  # Node exporter — VPC internal only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "9100"
    source_addresses = [var.vpc_cidr]
  }

  # Outbound — all traffic allowed (Docker pulls, API calls, etc.)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# ═══════════════════════════════════════════════════════════════
# DROPLET — Single-tenant workflow runtime
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_droplet" "main" {
  name     = "ab-kyc-anomaly-detector-to-reduce-fraud-los"
  region   = var.region
  size     = var.instance_type
  image    = var.image
  vpc_uuid = digitalocean_vpc.main.id
  ssh_keys = var.ssh_public_key != "" ? [digitalocean_ssh_key.deploy[0].fingerprint] : []

  monitoring = true
  backups    = var.enable_backups
  ipv6       = true
  graceful_shutdown = true

  user_data = file("${path.module}/scripts/cloud-init.yml")

  tags = concat([
    "agentbridge",
    "blueprint-kyc-anomaly-detector-to-reduce-fraud-los",
    var.environment,
    "managed-by:terraform",
    "workflow-id:${var.workflow_id}",
  ], var.extra_tags)

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = self.ipv4_address
  }

  # Wait for cloud-init to complete before declaring healthy
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "echo 'Cloud-init complete'",
    ]
  }
}

# ═══════════════════════════════════════════════════════════════
# RESERVED IP (replaces deprecated floating_ip)
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_reserved_ip" "main" {
  count  = var.enable_static_ip ? 1 : 0
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "main" {
  count      = var.enable_static_ip ? 1 : 0
  ip_address = digitalocean_reserved_ip.main[0].ip_address
  droplet_id = digitalocean_droplet.main.id
}

# ═══════════════════════════════════════════════════════════════
# BLOCK STORAGE — Persistent data volume
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_volume" "data" {
  count                   = var.additional_storage_gb > 0 ? 1 : 0
  region                  = var.region
  name                    = "ab-kyc-anomaly-detector-to-reduce-fraud-los-data"
  size                    = var.additional_storage_gb
  initial_filesystem_type = "ext4"
  description             = "Persistent data for AgentBridge KYC Anomaly Detector to reduce fraud loss"

  tags = ["agentbridge", "blueprint-kyc-anomaly-detector-to-reduce-fraud-los", "data"]
}

resource "digitalocean_volume_attachment" "data" {
  count      = var.additional_storage_gb > 0 ? 1 : 0
  droplet_id = digitalocean_droplet.main.id
  volume_id  = digitalocean_volume.data[0].id
}

# ═══════════════════════════════════════════════════════════════
# SPACES BUCKET — Artifact storage (S3-compatible)
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_spaces_bucket" "artifacts" {
  count  = var.enable_spaces ? 1 : 0
  name   = "ab-kyc-anomaly-detector-to-reduce-fraud-los-artifacts"
  region = var.spaces_region
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    expiration {
      days = 90
    }
    noncurrent_version_expiration {
      days = 30
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["https://*"]
    max_age_seconds = 3600
  }
}

# ═══════════════════════════════════════════════════════════════
# LOAD BALANCER — Optional, for workflows exposing HTTP endpoints
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_loadbalancer" "main" {
  count  = var.enable_load_balancer ? 1 : 0
  name   = "ab-kyc-anomaly-detector-to-reduce-fraud-los-lb"
  region = var.region
  vpc_uuid = digitalocean_vpc.main.id

  forwarding_rule {
    entry_port      = 443
    entry_protocol  = "https"
    target_port     = 80
    target_protocol = "http"
    certificate_name = var.certificate_id
  }

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }

  droplet_ids = [digitalocean_droplet.main.id]

  redirect_http_to_https = true
  enable_proxy_protocol  = false
}

# ═══════════════════════════════════════════════════════════════
# MONITORING ALERTS — DigitalOcean native alerting
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_monitor_alert" "cpu_high" {
  alerts {
    email = var.alert_emails
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 85
  enabled     = true
  entities    = [digitalocean_droplet.main.id]
  description = "AgentBridge kyc-anomaly-detector-to-reduce-fraud-los: CPU > 85% for 5 min"
}

resource "digitalocean_monitor_alert" "memory_high" {
  alerts {
    email = var.alert_emails
  }
  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 90
  enabled     = true
  entities    = [digitalocean_droplet.main.id]
  description = "AgentBridge kyc-anomaly-detector-to-reduce-fraud-los: Memory > 90% for 5 min"
}

resource "digitalocean_monitor_alert" "disk_high" {
  alerts {
    email = var.alert_emails
  }
  window      = "15m"
  type        = "v1/insights/droplet/disk_utilization_percent"
  compare     = "GreaterThan"
  value       = 85
  enabled     = true
  entities    = [digitalocean_droplet.main.id]
  description = "AgentBridge kyc-anomaly-detector-to-reduce-fraud-los: Disk > 85%"
}

# ═══════════════════════════════════════════════════════════════
# DOMAIN RECORD — Optional DNS (if DO manages the domain)
# ═══════════════════════════════════════════════════════════════
resource "digitalocean_record" "main" {
  count  = var.custom_domain != "" && var.domain_name != "" ? 1 : 0
  domain = var.domain_name
  type   = "A"
  name   = var.custom_domain
  value  = var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address
  ttl    = 300
}
