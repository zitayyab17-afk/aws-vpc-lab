# ---------- Bastion: SSH only from my own IP address ----------
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "SSH from my IP only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-bastion-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from my IP"
  cidr_ipv4         = var.my_ip_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------- Private app server: SSH only from the bastion ----------
resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "SSH from the bastion only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from bastion"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound, through the NAT gateway"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------- Database: PostgreSQL only from the bastion and app server, never from the internet ----------
resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "PostgreSQL from bastion and app only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_bastion" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from bastion"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from app server"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
