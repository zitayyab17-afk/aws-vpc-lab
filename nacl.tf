# ---------- Network ACLs: a second, subnet-level firewall ----------
# Security groups protect each instance (stateful). NACLs protect each subnet and are
# STATELESS, so return traffic on ephemeral ports (1024-65535) must be allowed explicitly.
# Anything not allowed below hits the built-in "deny all" rule (*).
# Traffic to the Amazon DNS resolver, instance metadata and time sync is not filtered by NACLs.

locals {
  public_cidrs = [aws_subnet.public_a.cidr_block, aws_subnet.public_b.cidr_block]
}

# Public subnets: bastion host and NAT gateway
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # --- inbound ---
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.my_ip_cidr # SSH to the bastion, from my IP only
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # private servers sending HTTP through the NAT gateway
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # private servers sending HTTPS through the NAT gateway
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # return traffic for connections started from inside
    from_port  = 1024
    to_port    = 65535
  }

  # --- outbound ---
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # updates via HTTP
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # updates via HTTPS
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # bastion SSH jump to the private app server
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # bastion to PostgreSQL
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # replies to my SSH session and to private servers via NAT
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.project}-public-nacl"
  }
}

# Private subnets: app server and RDS PostgreSQL
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # --- inbound ---
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.public_cidrs[0] # SSH only from the public subnets (bastion)
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 101
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.public_cidrs[1]
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # PostgreSQL from inside the VPC only
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # return traffic (updates via NAT, database replies)
    from_port  = 1024
    to_port    = 65535
  }

  # --- outbound ---
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # updates via HTTP, through the NAT gateway
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # updates via HTTPS, through the NAT gateway
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # app server to PostgreSQL in the other private subnet
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr # replies to the bastion and app server
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.project}-private-nacl"
  }
}
