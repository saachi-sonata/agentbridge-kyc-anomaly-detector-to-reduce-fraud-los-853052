# ═══════════════════════════════════════════════════════════════
# Authentication
# ═══════════════════════════════════════════════════════════════
variable "do_token" {
  description = "DigitalOcean Personal Access Token (read/write scope)"
  type        = string
  sensitive   = true
}

variable "spaces_access_id" {
  description = "Spaces access key ID (for remote state + artifact storage)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "Spaces secret key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "spaces_region" {
  description = "DigitalOcean Spaces region for remote state"
  type        = string
  default     = "nyc1"
}

# ═══════════════════════════════════════════════════════════════
# Compute
# ═══════════════════════════════════════════════════════════════
variable "region" {
  description = "DigitalOcean datacenter region"
  type        = string
  default     = "nyc1"

  validation {
    condition     = contains(["nyc1","nyc3","sfo2","sfo3","ams3","sgp1","lon1","fra1","tor1","blr1","syd1"], var.region)
    error_message = "Must be a valid DigitalOcean region slug."
  }
}

variable "instance_type" {
  description = "Droplet size slug (e.g., s-2vcpu-4gb, s-4vcpu-8gb)"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "image" {
  description = "Droplet OS image slug or custom snapshot ID"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "workflow_id" {
  description = "Unique workflow identifier for tagging and tracking"
  type        = string
  default     = ""
}

# ═══════════════════════════════════════════════════════════════
# Networking
# ═══════════════════════════════════════════════════════════════
variable "vpc_cidr" {
  description = "VPC CIDR range (one /24 per deployment for isolation)"
  type        = string
  default     = "10.100.0.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for Droplet access"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "SSH private key for provisioner connection"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed for SSH and application editor access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_static_ip" {
  description = "Assign a reserved IP address"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Subdomain for DNS record (requires domain_name)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "DigitalOcean-managed domain name"
  type        = string
  default     = ""
}

variable "certificate_id" {
  description = "DO managed certificate name (for load balancer HTTPS)"
  type        = string
  default     = ""
}

# ═══════════════════════════════════════════════════════════════
# Storage
# ═══════════════════════════════════════════════════════════════
variable "additional_storage_gb" {
  description = "Additional block storage volume in GB (0 to skip)"
  type        = number
  default     = 0

  validation {
    condition     = var.additional_storage_gb >= 0 && var.additional_storage_gb <= 16384
    error_message = "Block storage must be 0-16384 GB."
  }
}

variable "enable_spaces" {
  description = "Create a Spaces bucket for artifact storage"
  type        = bool
  default     = false
}

# ═══════════════════════════════════════════════════════════════
# Operations
# ═══════════════════════════════════════════════════════════════
variable "enable_backups" {
  description = "Enable weekly Droplet backups"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Create a load balancer in front of the Droplet"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Must be development, staging, or production."
  }
}

variable "alert_emails" {
  description = "Email addresses for monitoring alerts"
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "Additional Droplet tags"
  type        = list(string)
  default     = ["blueprint:KYC Anomaly Detector to reduce fraud loss","environment:production"]
}
