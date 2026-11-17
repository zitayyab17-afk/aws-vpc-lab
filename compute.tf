# Latest Amazon Linux 2023 image, looked up from the public AWS SSM parameter
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_key_pair" "lab" {
  key_name   = "${var.project}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# ---------- Bastion host in a public subnet: the only way in from the internet ----------
resource "aws_instance" "bastion" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.lab.key_name

  # PostgreSQL client, so I can connect to RDS from the bastion
  user_data = <<-EOT
    #!/bin/bash
    dnf install -y postgresql16
  EOT

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "${var.project}-bastion"
  }
}

# ---------- App server in a private subnet: no public IP, reached only through the bastion ----------
resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.lab.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "${var.project}-app"
  }

  # The private route (through the NAT gateway) must exist before first boot
  depends_on = [aws_route_table_association.private_a]
}
