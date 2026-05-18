# ═══════════════════════════════════════════════════════════════
# Compute Outputs
# ═══════════════════════════════════════════════════════════════
output "droplet_id" {
  description = "Droplet ID"
  value       = digitalocean_droplet.main.id
}

output "droplet_urn" {
  description = "Droplet URN for project assignment"
  value       = digitalocean_droplet.main.urn
}

output "droplet_ip" {
  description = "Droplet public IPv4 address"
  value       = digitalocean_droplet.main.ipv4_address
}

output "droplet_private_ip" {
  description = "Droplet private IPv4 (VPC)"
  value       = digitalocean_droplet.main.ipv4_address_private
}

output "reserved_ip" {
  description = "Reserved IP (if enabled)"
  value       = var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : null
}

output "effective_ip" {
  description = "Primary access IP (reserved or Droplet public)"
  value       = var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address
}

# ═══════════════════════════════════════════════════════════════
# Access Outputs
# ═══════════════════════════════════════════════════════════════
output "ssh_command" {
  description = "SSH connection command"
  value       = "ssh root@${var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address}"
}

output "application_url" {
  description = "AgentBridge workflow editor URL"
  value       = "http://${var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address}:5678"
}

output "health_url" {
  description = "Health check endpoint"
  value       = "http://${var.enable_static_ip ? digitalocean_reserved_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address}/health"
}

output "console_url" {
  description = "DigitalOcean console link"
  value       = "https://cloud.digitalocean.com/droplets/${digitalocean_droplet.main.id}"
}

# ═══════════════════════════════════════════════════════════════
# Network Outputs
# ═══════════════════════════════════════════════════════════════
output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR range"
  value       = digitalocean_vpc.main.ip_range
}

output "project_id" {
  description = "DigitalOcean Project ID"
  value       = digitalocean_project.main.id
}

output "firewall_id" {
  description = "Firewall ID"
  value       = digitalocean_firewall.main.id
}

# ═══════════════════════════════════════════════════════════════
# Storage Outputs
# ═══════════════════════════════════════════════════════════════
output "volume_id" {
  description = "Block storage volume ID (if enabled)"
  value       = var.additional_storage_gb > 0 ? digitalocean_volume.data[0].id : null
}

output "spaces_bucket" {
  description = "Spaces bucket name (if enabled)"
  value       = var.enable_spaces ? digitalocean_spaces_bucket.artifacts[0].name : null
}

output "spaces_endpoint" {
  description = "Spaces bucket endpoint (if enabled)"
  value       = var.enable_spaces ? digitalocean_spaces_bucket.artifacts[0].bucket_domain_name : null
}

# ═══════════════════════════════════════════════════════════════
# Load Balancer Outputs
# ═══════════════════════════════════════════════════════════════
output "lb_ip" {
  description = "Load balancer IP (if enabled)"
  value       = var.enable_load_balancer ? digitalocean_loadbalancer.main[0].ip : null
}

output "lb_id" {
  description = "Load balancer ID (if enabled)"
  value       = var.enable_load_balancer ? digitalocean_loadbalancer.main[0].id : null
}
