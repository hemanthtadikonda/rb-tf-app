output "prometheus_ip" {
  value = "${aws_instance.main.private_ip}/32"
}
output "prometheus" {
  value = aws_instance.main.private_ip
}