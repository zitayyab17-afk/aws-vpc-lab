output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_public_ip" {
  value = aws_eip.nat.public_ip
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

output "db_password_secret_arn" {
  description = "Secrets Manager secret that holds the database password"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "db_snapshot_encrypted" {
  value = var.create_manual_snapshot ? aws_db_snapshot.manual[0].encrypted : null
}

output "ssh_to_bastion" {
  value = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_to_app_via_bastion" {
  value = "ssh -i ~/.ssh/id_ed25519 -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.app.private_ip}"
}
