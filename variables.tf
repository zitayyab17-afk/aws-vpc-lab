variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "vpc-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR form, e.g. 81.2.3.4/32. Only this IP can SSH to the bastion."
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0)) && var.my_ip_cidr != "0.0.0.0/0"
    error_message = "Use your own IP with /32, never 0.0.0.0/0."
  }
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key, used for the bastion and the private instance"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "instance_type" {
  description = "EC2 instance type for the bastion and the private instance"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the initial PostgreSQL database"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Master username for PostgreSQL (the password is generated and kept in Secrets Manager)"
  type        = string
  default     = "labadmin"
}

variable "db_backup_retention_days" {
  description = "Automated backup retention in days. Set to 0 if a free-plan account rejects 1."
  type        = number
  default     = 1
}

variable "create_manual_snapshot" {
  description = "Take a manual (encrypted) snapshot of the database after it is created"
  type        = bool
  default     = true
}
